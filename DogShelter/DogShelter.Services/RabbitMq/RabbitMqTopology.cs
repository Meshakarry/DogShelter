using RabbitMQ.Client;

namespace DogShelter.Services.RabbitMq;

public static class RabbitMqTopology
{
    public const string EmailExchange = "email-exchange";
    public const string EmailQueue = "email-queue";
    public const string EmailRoutingKey = "email-queue";

    public const string RetryExchange = "email-retry-exchange";
    public const string FailedExchange = "email-failed-exchange";
    public const string FailedQueue = "email-failed";
    public const string FailedRoutingKey = "email-failed";

    public const string RetryCountHeader = "x-retry-count";
    public const int MaxRetryAttempts = 4;

    private static readonly (string RoutingKey, int DelayMs)[] RetryLevels =
    [
        ("retry-1s", 1000),
        ("retry-2s", 2000),
        ("retry-4s", 4000),
        ("retry-8s", 8000)
    ];

    public static void Declare(IModel channel)
    {
        channel.ExchangeDeclare(EmailExchange, ExchangeType.Direct, durable: true, autoDelete: false);
        channel.QueueDeclare(EmailQueue, durable: true, exclusive: false, autoDelete: false);
        channel.QueueBind(EmailQueue, EmailExchange, EmailRoutingKey);

        channel.ExchangeDeclare(FailedExchange, ExchangeType.Direct, durable: true, autoDelete: false);
        channel.QueueDeclare(FailedQueue, durable: true, exclusive: false, autoDelete: false);
        channel.QueueBind(FailedQueue, FailedExchange, FailedRoutingKey);

        channel.ExchangeDeclare(RetryExchange, ExchangeType.Direct, durable: true, autoDelete: false);
        foreach (var (routingKey, delayMs) in RetryLevels)
        {
            var queueName = $"email-{routingKey}";
            var args = new Dictionary<string, object>
            {
                { "x-message-ttl", delayMs },
                { "x-dead-letter-exchange", EmailExchange },
                { "x-dead-letter-routing-key", EmailRoutingKey }
            };
            channel.QueueDeclare(queueName, durable: true, exclusive: false, autoDelete: false, arguments: args);
            channel.QueueBind(queueName, RetryExchange, routingKey);
        }
    }

    /// <summary>Routing key for the retry queue matching the given zero-based attempt number (0 = first retry, after the initial delivery failed).</summary>
    public static string RetryRoutingKeyFor(int attempt) => RetryLevels[attempt].RoutingKey;
}
