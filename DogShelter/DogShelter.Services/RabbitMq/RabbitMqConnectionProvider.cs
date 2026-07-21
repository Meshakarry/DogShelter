using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using RabbitMQ.Client;

namespace DogShelter.Services.RabbitMq;

public sealed class RabbitMqConnectionProvider : IRabbitMqConnectionProvider
{
    private readonly IConfiguration _configuration;
    private readonly ILogger<RabbitMqConnectionProvider> _logger;
    private readonly string _clientProvidedName;
    private readonly object _sync = new();
    private IConnection? _connection;
    private bool _disposed;

    public RabbitMqConnectionProvider(
        IConfiguration configuration,
        ILogger<RabbitMqConnectionProvider> logger,
        string clientProvidedName)
    {
        _configuration = configuration;
        _logger = logger;
        _clientProvidedName = clientProvidedName;
    }

    public IConnection GetConnection()
    {
        ObjectDisposedException.ThrowIf(_disposed, this);

        lock (_sync)
        {
            if (_connection != null && _connection.IsOpen)
                return _connection;

            DisposeConnectionInternal();

            var factory = RabbitMqConnectionSettings.CreateFactory(_configuration, _clientProvidedName);
            _connection = factory.CreateConnection();
            _connection.ConnectionShutdown += (_, args) =>
                _logger.LogWarning(
                    "RabbitMQ connection shutdown ({ClientName}): {Reason}. Will reconnect on next use.",
                    _clientProvidedName,
                    args.ReplyText);

            _logger.LogInformation(
                "RabbitMQ connected ({ClientName}) at {Host}:{Port}.",
                _clientProvidedName,
                factory.HostName,
                factory.Port);

            return _connection;
        }
    }

    public void Dispose()
    {
        if (_disposed)
            return;

        _disposed = true;
        lock (_sync)
        {
            DisposeConnectionInternal();
        }
    }

    private void DisposeConnectionInternal()
    {
        try
        {
            _connection?.Close();
            _connection?.Dispose();
        }
        catch (Exception ex)
        {
            _logger.LogDebug(ex, "Error closing RabbitMQ connection ({ClientName}).", _clientProvidedName);
        }
        finally
        {
            _connection = null;
        }
    }
}
