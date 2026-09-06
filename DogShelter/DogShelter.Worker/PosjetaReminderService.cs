using DogShelter.Services.Constants;
using DogShelter.Services.Database;
using DogShelter.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DogShelter.Worker;

/// <summary>
/// Periodically finds confirmed visits happening soon and sends each visitor a one-time email
/// reminder. The reference architecture assigns this job to the Worker; the email itself goes
/// through the same RabbitMQ queue/consumer as every other outgoing message in the app.
/// </summary>
public class PosjetaReminderService : BackgroundService
{
    private static readonly TimeSpan CheckInterval = TimeSpan.FromMinutes(30);
    private static readonly TimeSpan ReminderWindow = TimeSpan.FromHours(24);

    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<PosjetaReminderService> _logger;

    public PosjetaReminderService(IServiceScopeFactory scopeFactory, ILogger<PosjetaReminderService> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        using var timer = new PeriodicTimer(CheckInterval);

        // Run once immediately on startup, then on the timer - otherwise a visit inside the
        // reminder window would wait up to CheckInterval after the Worker starts before anyone
        // even looks for it.
        do
        {
            try
            {
                await SendDueRemindersAsync(stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error while checking for posjeta reminders.");
            }
        } while (!stoppingToken.IsCancellationRequested && await timer.WaitForNextTickAsync(stoppingToken));
    }

    private async Task SendDueRemindersAsync(CancellationToken cancellationToken)
    {
        using var scope = _scopeFactory.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<DogShelterContext>();
        var emailSender = scope.ServiceProvider.GetRequiredService<IEmailSender>();

        var now = DateTime.UtcNow;
        var windowEnd = now.Add(ReminderWindow);

        var due = await context.Posjeta
            .Include(p => p.Korisnik)
            .Include(p => p.Pas)
            .Include(p => p.StatusPosjete)
            .Where(p => p.StatusPosjete.Naziv == StatusPosjeteNazivi.Potvrdjena
                && !p.PodsjetnikPoslan
                && p.DatumVrijeme > now
                && p.DatumVrijeme <= windowEnd)
            .ToListAsync(cancellationToken);

        if (due.Count == 0) return;

        foreach (var posjeta in due)
        {
            try
            {
                var subject = "Podsjetnik za predstojeću posjetu";
                var body = $"Poštovani/a {posjeta.Korisnik.Ime},\n\n" +
                           $"Podsjećamo Vas na zakazanu posjetu {posjeta.DatumVrijeme:dd.MM.yyyy. u HH:mm}" +
                           (posjeta.Pas != null ? $" psu \"{posjeta.Pas.Naziv}\"" : " azilu") +
                           ".\n\nAzil za pse Bugojno";

                await emailSender.SendAsync(posjeta.Korisnik.Email, subject, body);

                // Marked immediately after queuing (not after the email is actually delivered) so
                // a slow/failed SMTP send downstream can't cause this sweep to re-queue the same
                // reminder on its next tick - same "queued = handled from here on" boundary the
                // rest of the app already draws between an API action and the Worker's delivery.
                posjeta.PodsjetnikPoslan = true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to queue posjeta reminder for PosjetaId {PosjetaId}.", posjeta.PosjetaId);
            }
        }

        await context.SaveChangesAsync(cancellationToken);
        _logger.LogInformation("Sent {Count} posjeta reminder(s).", due.Count);
    }
}
