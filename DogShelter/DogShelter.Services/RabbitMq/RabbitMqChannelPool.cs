using Microsoft.Extensions.Logging;
using RabbitMQ.Client;

namespace DogShelter.Services.RabbitMq;

public sealed class RabbitMqChannelPool : IRabbitMqChannelPool
{
    private readonly IRabbitMqConnectionProvider _connectionProvider;
    private readonly ILogger<RabbitMqChannelPool> _logger;
    private readonly int _maxPoolSize;
    private readonly object _sync = new();
    private readonly Stack<IModel> _available = new();
    private bool _disposed;

    public RabbitMqChannelPool(
        IRabbitMqConnectionProvider connectionProvider,
        ILogger<RabbitMqChannelPool> logger,
        int maxPoolSize = 2)
    {
        _connectionProvider = connectionProvider;
        _logger = logger;
        _maxPoolSize = Math.Max(1, maxPoolSize);
    }

    public IModel RentChannel()
    {
        ObjectDisposedException.ThrowIf(_disposed, this);

        lock (_sync)
        {
            while (_available.Count > 0)
            {
                var channel = _available.Pop();
                if (channel.IsOpen)
                    return channel;

                channel.Dispose();
            }

            var created = _connectionProvider.GetConnection().CreateModel();
            RabbitMqTopology.Declare(created);
            _logger.LogDebug("RabbitMQ publish channel created.");
            return created;
        }
    }

    public void ReturnChannel(IModel channel)
    {
        if (channel == null)
            return;

        lock (_sync)
        {
            if (_disposed || !channel.IsOpen)
            {
                SafeDispose(channel);
                return;
            }

            if (_available.Count < _maxPoolSize)
            {
                _available.Push(channel);
                return;
            }

            SafeDispose(channel);
        }
    }

    public void Dispose()
    {
        if (_disposed)
            return;

        _disposed = true;
        lock (_sync)
        {
            while (_available.Count > 0)
                SafeDispose(_available.Pop());
        }
    }

    private static void SafeDispose(IModel channel)
    {
        try
        {
            channel.Close();
            channel.Dispose();
        }
        catch
        {
            // ignore shutdown races
        }
    }
}
