using RabbitMQ.Client;

namespace DogShelter.Services.RabbitMq;

/// <summary>Shared long-lived RabbitMQ connection per process (reconnects on demand). Never open a new connection per publish/consume call.</summary>
public interface IRabbitMqConnectionProvider : IDisposable
{
    IConnection GetConnection();
}
