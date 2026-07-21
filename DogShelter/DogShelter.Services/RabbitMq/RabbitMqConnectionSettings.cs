using Microsoft.Extensions.Configuration;
using RabbitMQ.Client;

namespace DogShelter.Services.RabbitMq;

public static class RabbitMqConnectionSettings
{
    public static ConnectionFactory CreateFactory(IConfiguration configuration, string clientProvidedName)
    {
        var section = configuration.GetSection("RabbitMQ");
        var host = section["Host"] ?? "localhost";
        var port = int.TryParse(section["Port"], out var parsedPort) ? parsedPort : 5672;
        var userName = section["Username"] ?? "guest";
        var password = section["Password"] ?? "guest";

        return new ConnectionFactory
        {
            HostName = host,
            Port = port,
            UserName = userName,
            Password = password,
            AutomaticRecoveryEnabled = true,
            NetworkRecoveryInterval = TimeSpan.FromSeconds(10),
            RequestedConnectionTimeout = TimeSpan.FromSeconds(30),
            RequestedHeartbeat = TimeSpan.FromSeconds(60),
            DispatchConsumersAsync = true,
            ClientProvidedName = clientProvidedName
        };
    }
}
