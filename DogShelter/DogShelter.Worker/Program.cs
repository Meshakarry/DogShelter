using DogShelter.Services.Database;
using DogShelter.Services.Interfaces;
using DogShelter.Services.RabbitMq;
using DogShelter.Services.Services;
using DogShelter.Worker;
using Microsoft.EntityFrameworkCore;

DotNetEnv.Env.TraversePath().Load();

var builder = Host.CreateApplicationBuilder(args);
builder.Services.AddRabbitMqConnection(connectionClientName: "DogShelter Worker");
builder.Services.AddHostedService<EmailQueueConsumer>();

// PosjetaReminderService needs both DB access (to find upcoming visits) and a way to send mail -
// it publishes reminder emails onto the same RabbitMQ email queue EmailQueueConsumer above
// already consumes in this same process, so it inherits that consumer's retry/failed-queue
// handling for free instead of sending SMTP directly itself.
builder.Services.AddDbContext<DogShelterContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DogShelter")));
builder.Services.AddRabbitMqMailInfrastructure(connectionClientName: "DogShelter Worker Reminders");
builder.Services.AddScoped<IEmailSender, QueuedEmailSender>();
builder.Services.AddHostedService<PosjetaReminderService>();

var host = builder.Build();
host.Run();
