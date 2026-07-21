using System.Text;
using System.Text.Json;
using DogShelter.Services.Interfaces;
using DogShelter.Services.RabbitMq;
using Microsoft.Extensions.Logging;
using RabbitMQ.Client;

namespace DogShelter.Services.Services;

/// <summary>Publishes outgoing email to RabbitMQ instead of sending it directly — the DogShelter.Worker process performs the actual SMTP send.</summary>
public class QueuedEmailSender : IEmailSender
{
    private readonly IRabbitMqChannelPool _channelPool;
    private readonly ILogger<QueuedEmailSender> _logger;

    public QueuedEmailSender(IRabbitMqChannelPool channelPool, ILogger<QueuedEmailSender> logger)
    {
        _channelPool = channelPool;
        _logger = logger;
    }

    public Task SendAsync(string toEmail, string subject, string body)
    {
        var message = new EmailMessage { To = toEmail, Subject = subject, Body = body };
        var payload = Encoding.UTF8.GetBytes(JsonSerializer.Serialize(message));

        var channel = _channelPool.RentChannel();
        try
        {
            var props = channel.CreateBasicProperties();
            props.ContentType = "application/json";
            props.DeliveryMode = 2;
            props.Persistent = true;
            props.Headers = new Dictionary<string, object> { { RabbitMqTopology.RetryCountHeader, 0 } };

            channel.BasicPublish(
                exchange: RabbitMqTopology.EmailExchange,
                routingKey: RabbitMqTopology.EmailRoutingKey,
                mandatory: false,
                basicProperties: props,
                body: payload);

            _logger.LogInformation("Email message queued for {Recipient}.", toEmail);
        }
        finally
        {
            _channelPool.ReturnChannel(channel);
        }

        return Task.CompletedTask;
    }
}
