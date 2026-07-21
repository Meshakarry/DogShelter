using DogShelter.Services.RabbitMq;
using DogShelter.Worker;

DotNetEnv.Env.TraversePath().Load();

var builder = Host.CreateApplicationBuilder(args);
builder.Services.AddRabbitMqConnection(connectionClientName: "DogShelter Worker");
builder.Services.AddHostedService<EmailQueueConsumer>();

var host = builder.Build();
host.Run();
