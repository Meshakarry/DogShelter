using RabbitMQ.Client;

namespace DogShelter.Services.RabbitMq;

/// <summary>Pool of publish channels on the shared connection — avoids opening a new channel per publish call.</summary>
public interface IRabbitMqChannelPool : IDisposable
{
    IModel RentChannel();

    void ReturnChannel(IModel channel);
}
