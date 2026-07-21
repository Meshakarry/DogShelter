using System.Net;
using System.Net.Mail;
using System.Text;
using System.Text.Json;
using DogShelter.Services.RabbitMq;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using RabbitMQ.Client.Exceptions;

namespace DogShelter.Worker;

/// <summary>
/// Consumes queued email messages from RabbitMQ and sends them via SMTP.
/// This is the "real async work" second service required alongside the API — see faculty-requirements.
/// </summary>
public class EmailQueueConsumer : BackgroundService
{
    private readonly ILogger<EmailQueueConsumer> _logger;
    private readonly IConfiguration _configuration;
    private readonly IRabbitMqConnectionProvider _connectionProvider;
    private readonly SemaphoreSlim _processingLock = new(1, 1);
    private IModel? _channel;
    private bool _consumerRegistered;

    public EmailQueueConsumer(
        ILogger<EmailQueueConsumer> logger,
        IConfiguration configuration,
        IRabbitMqConnectionProvider connectionProvider)
    {
        _logger = logger;
        _configuration = configuration;
        _connectionProvider = connectionProvider;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                if (!IsChannelReady())
                    ConnectChannel();

                if (!IsChannelReady())
                {
                    await Task.Delay(TimeSpan.FromSeconds(5), stoppingToken);
                    continue;
                }

                if (!_consumerRegistered)
                    RegisterConsumer();

                await Task.Delay(TimeSpan.FromSeconds(1), stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                break;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error in email queue consumer loop.");
                TeardownChannel();
                await Task.Delay(TimeSpan.FromSeconds(5), stoppingToken);
            }
        }
    }

    public override Task StopAsync(CancellationToken cancellationToken)
    {
        TeardownChannel();
        return base.StopAsync(cancellationToken);
    }

    private bool IsChannelReady() => _channel != null && _channel.IsOpen;

    private void ConnectChannel()
    {
        TeardownChannel();
        try
        {
            var connection = _connectionProvider.GetConnection();
            _channel = connection.CreateModel();
            RabbitMqTopology.Declare(_channel);
            _consumerRegistered = false;
            _logger.LogInformation("Email queue consumer channel ready on queue {QueueName}.", RabbitMqTopology.EmailQueue);
        }
        catch (BrokerUnreachableException ex)
        {
            _logger.LogWarning(ex, "RabbitMQ broker unreachable. Retrying...");
            TeardownChannel();
        }
        catch (OperationInterruptedException ex)
        {
            _logger.LogError(ex, "RabbitMQ topology declaration failed for queue {QueueName}.", RabbitMqTopology.EmailQueue);
            TeardownChannel();
        }
    }

    private void RegisterConsumer()
    {
        if (_channel == null)
            return;

        var consumer = new AsyncEventingBasicConsumer(_channel);
        consumer.Received += OnMessageReceivedAsync;

        _channel.BasicQos(prefetchSize: 0, prefetchCount: 1, global: false);
        _channel.BasicConsume(queue: RabbitMqTopology.EmailQueue, autoAck: false, consumer: consumer);
        _consumerRegistered = true;
        _logger.LogInformation("Email queue consumer listening on queue {QueueName}.", RabbitMqTopology.EmailQueue);
    }

    private async Task OnMessageReceivedAsync(object sender, BasicDeliverEventArgs ea)
    {
        await _processingLock.WaitAsync();
        try
        {
            var body = Encoding.UTF8.GetString(ea.Body.ToArray());
            EmailMessage message;
            try
            {
                message = ParseMessage(body);
            }
            catch (InvalidEmailMessageException ex)
            {
                _logger.LogError(ex, "Discarding malformed email message (delivery tag {DeliveryTag}).", ea.DeliveryTag);
                PublishToFailedQueue(ea.BasicProperties, body);
                _channel!.BasicAck(ea.DeliveryTag, multiple: false);
                return;
            }

            try
            {
                await SendEmailAsync(message, CancellationToken.None);
                _channel!.BasicAck(ea.DeliveryTag, multiple: false);
                _logger.LogInformation("Email sent to {Recipient}.", message.To);
            }
            catch (Exception ex)
            {
                HandleTransientFailure(ea, body, ex);
            }
        }
        finally
        {
            _processingLock.Release();
        }
    }

    private void HandleTransientFailure(BasicDeliverEventArgs ea, string body, Exception ex)
    {
        var attempt = GetRetryCount(ea.BasicProperties);

        if (attempt >= RabbitMqTopology.MaxRetryAttempts)
        {
            _logger.LogError(ex, "Email send failed after {Attempts} attempts; routing to failed queue (delivery tag {DeliveryTag}).", attempt, ea.DeliveryTag);
            PublishToFailedQueue(ea.BasicProperties, body);
        }
        else
        {
            _logger.LogWarning(ex, "Email send failed (attempt {Attempt}); scheduling retry (delivery tag {DeliveryTag}).", attempt + 1, ea.DeliveryTag);
            PublishToRetryQueue(attempt, body);
        }

        _channel!.BasicAck(ea.DeliveryTag, multiple: false);
    }

    private void PublishToRetryQueue(int attempt, string body)
    {
        var props = _channel!.CreateBasicProperties();
        props.ContentType = "application/json";
        props.DeliveryMode = 2;
        props.Persistent = true;
        props.Headers = new Dictionary<string, object> { { RabbitMqTopology.RetryCountHeader, attempt + 1 } };

        _channel.BasicPublish(
            exchange: RabbitMqTopology.RetryExchange,
            routingKey: RabbitMqTopology.RetryRoutingKeyFor(attempt),
            mandatory: false,
            basicProperties: props,
            body: Encoding.UTF8.GetBytes(body));
    }

    private void PublishToFailedQueue(IBasicProperties? originalProps, string body)
    {
        var props = _channel!.CreateBasicProperties();
        props.ContentType = "application/json";
        props.DeliveryMode = 2;
        props.Persistent = true;
        if (originalProps?.Headers != null)
            props.Headers = originalProps.Headers;

        _channel.BasicPublish(
            exchange: RabbitMqTopology.FailedExchange,
            routingKey: RabbitMqTopology.FailedRoutingKey,
            mandatory: false,
            basicProperties: props,
            body: Encoding.UTF8.GetBytes(body));
    }

    private static int GetRetryCount(IBasicProperties? props)
    {
        if (props?.Headers != null && props.Headers.TryGetValue(RabbitMqTopology.RetryCountHeader, out var value))
        {
            try
            {
                return Convert.ToInt32(value);
            }
            catch
            {
                return 0;
            }
        }

        return 0;
    }

    private static EmailMessage ParseMessage(string body)
    {
        EmailMessage? message;
        try
        {
            message = JsonSerializer.Deserialize<EmailMessage>(body, new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
        }
        catch (JsonException ex)
        {
            throw new InvalidEmailMessageException("Email queue payload is not valid JSON.", ex);
        }

        if (message == null)
            throw new InvalidEmailMessageException("Email queue payload deserialized to null.");
        if (string.IsNullOrWhiteSpace(message.To))
            throw new InvalidEmailMessageException("Email queue payload is missing 'To'.");
        if (string.IsNullOrWhiteSpace(message.Subject))
            throw new InvalidEmailMessageException("Email queue payload is missing 'Subject'.");

        return message;
    }

    private async Task SendEmailAsync(EmailMessage message, CancellationToken cancellationToken)
    {
        var smtp = _configuration.GetSection("SMTP");
        var host = smtp["Host"];
        var port = int.TryParse(smtp["Port"], out var p) ? p : 587;
        var username = smtp["Username"];
        var password = smtp["Password"];
        var useSsl = !bool.TryParse(smtp["UseSsl"], out var ssl) || ssl;
        var senderName = smtp["SenderName"] ?? "DogShelter";

        if (string.IsNullOrWhiteSpace(host) || string.IsNullOrWhiteSpace(username))
        {
            _logger.LogWarning("SMTP not configured; skipping email send to {Recipient}.", message.To);
            return;
        }

        using var client = new SmtpClient(host, port)
        {
            Credentials = new NetworkCredential(username, password),
            EnableSsl = useSsl
        };

        using var mail = new MailMessage
        {
            From = new MailAddress(username, senderName),
            Subject = message.Subject,
            Body = message.Body,
            IsBodyHtml = false
        };
        mail.To.Add(message.To);

        await client.SendMailAsync(mail, cancellationToken);
    }

    private void TeardownChannel()
    {
        _consumerRegistered = false;
        try
        {
            _channel?.Close();
            _channel?.Dispose();
        }
        catch (Exception ex)
        {
            _logger.LogDebug(ex, "Error closing email queue channel.");
        }
        finally
        {
            _channel = null;
        }
    }

    private sealed class InvalidEmailMessageException : Exception
    {
        public InvalidEmailMessageException(string message) : base(message) { }
        public InvalidEmailMessageException(string message, Exception innerException) : base(message, innerException) { }
    }
}
