using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace DogShelter.Services.RabbitMq;

public static class RabbitMqServiceCollectionExtensions
{
    /// <summary>API side: shared connection + publish channel pool, for services that publish messages.</summary>
    public static IServiceCollection AddRabbitMqMailInfrastructure(
        this IServiceCollection services,
        string connectionClientName = "DogShelter API",
        int channelPoolSize = 2)
    {
        services.AddSingleton<IRabbitMqConnectionProvider>(sp =>
            new RabbitMqConnectionProvider(
                sp.GetRequiredService<IConfiguration>(),
                sp.GetRequiredService<ILogger<RabbitMqConnectionProvider>>(),
                connectionClientName));

        services.AddSingleton<IRabbitMqChannelPool>(sp =>
            new RabbitMqChannelPool(
                sp.GetRequiredService<IRabbitMqConnectionProvider>(),
                sp.GetRequiredService<ILogger<RabbitMqChannelPool>>(),
                channelPoolSize));

        return services;
    }

    /// <summary>Worker side: shared connection only — the consumer owns its own long-lived channel.</summary>
    public static IServiceCollection AddRabbitMqConnection(
        this IServiceCollection services,
        string connectionClientName = "DogShelter Worker")
    {
        services.AddSingleton<IRabbitMqConnectionProvider>(sp =>
            new RabbitMqConnectionProvider(
                sp.GetRequiredService<IConfiguration>(),
                sp.GetRequiredService<ILogger<RabbitMqConnectionProvider>>(),
                connectionClientName));

        return services;
    }
}
