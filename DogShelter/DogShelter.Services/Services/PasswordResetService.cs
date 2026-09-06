using System.Security.Cryptography;
using DogShelter.Model.Requests;
using DogShelter.Services.Database;
using DogShelter.Services.Exceptions;
using DogShelter.Services.Interfaces;
using Microsoft.AspNetCore.Hosting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace DogShelter.Services.Services;

public class PasswordResetService : IPasswordResetService
{
    private const int MaxResetRequestsPerWindow = 3;
    private static readonly TimeSpan ResetRequestWindow = TimeSpan.FromMinutes(15);
    private static readonly TimeSpan TokenLifetime = TimeSpan.FromMinutes(30);

    private const string GenericInvalidCodeMessage = "Kod za resetiranje nije ispravan ili je istekao.";

    private readonly DogShelterContext _context;
    private readonly IEmailSender _emailSender;
    private readonly IWebHostEnvironment _env;
    private readonly ILogger<PasswordResetService> _logger;

    public PasswordResetService(
        DogShelterContext context,
        IEmailSender emailSender,
        IWebHostEnvironment env,
        ILogger<PasswordResetService> logger)
    {
        _context = context;
        _emailSender = emailSender;
        _env = env;
        _logger = logger;
    }

    public async Task RequestResetAsync(RequestPasswordResetRequest request)
    {
        var user = await _context.Korisniks
            .FirstOrDefaultAsync(k => k.Email == request.Email && k.Aktivan);
        if (user == null)
            return;

        var windowStart = DateTime.UtcNow.Subtract(ResetRequestWindow);
        var recentRequests = await _context.LozinkaResetTokens
            .CountAsync(t => t.KorisnikId == user.KorisnikId && t.DatumKreiranja >= windowStart);
        if (recentRequests >= MaxResetRequestsPerWindow)
        {
            _logger.LogWarning("Password reset rate limit hit for user {UserId}.", user.KorisnikId);
            return;
        }

        var unusedTokens = await _context.LozinkaResetTokens
            .Where(t => t.KorisnikId == user.KorisnikId && !t.Iskoristen)
            .ToListAsync();
        foreach (var token in unusedTokens)
            token.Iskoristen = true;

        var code = GenerateResetCode();
        _context.LozinkaResetTokens.Add(new LozinkaResetToken
        {
            KorisnikId = user.KorisnikId,
            KodHash = HashResetCode(code),
            DatumKreiranja = DateTime.UtcNow,
            IsticeU = DateTime.UtcNow.Add(TokenLifetime),
            Iskoristen = false
        });
        await _context.SaveChangesAsync();

        if (_env.IsDevelopment())
            _logger.LogInformation("[DEV ONLY] Password reset code for {Email}: {Code}", user.Email, code);

        var subject = "Reset lozinke - DogShelter";
        var body = $"Poštovani/a {user.Ime},\n\n" +
                   $"Vaš kod za resetiranje lozinke je: {code}\n" +
                   "Kod ističe za 30 minuta.\n\n" +
                   "Ako niste zatražili resetiranje lozinke, ignorišite ovu poruku.\n\n" +
                   "DogShelter tim";

        // Retries a transient RabbitMQ reconnect blip; SMTP delivery itself is the Worker's own
        // retry/backoff. Response never reveals send outcome, to avoid email enumeration.
        const int maxAttempts = 3;
        for (var attempt = 1; attempt <= maxAttempts; attempt++)
        {
            try
            {
                await _emailSender.SendAsync(user.Email, subject, body);
                break;
            }
            catch (Exception ex) when (attempt < maxAttempts)
            {
                _logger.LogWarning(ex, "Attempt {Attempt} to queue password reset email for {Email} failed, retrying.", attempt, user.Email);
                await Task.Delay(TimeSpan.FromMilliseconds(300 * attempt));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to queue password reset email to {Email} after {Attempts} attempts.", user.Email, maxAttempts);
            }
        }
    }

    public async Task ResetPasswordAsync(ResetPasswordRequest request)
    {
        var user = await _context.Korisniks
            .FirstOrDefaultAsync(k => k.Email == request.Email && k.Aktivan);
        if (user == null)
            throw new ValidationException(GenericInvalidCodeMessage);

        await using var tx = await _context.Database.BeginTransactionAsync();
        try
        {
            // bcrypt hashes carry their own per-hash salt, so the code can't be matched with a
            // WHERE KodHash == x query - load the user's live candidate tokens and verify against
            // each. RequestResetAsync marks every earlier unused token as spent, so in practice
            // this is a single row.
            var candidates = await _context.LozinkaResetTokens
                .Where(t => t.KorisnikId == user.KorisnikId && !t.Iskoristen && t.IsticeU > DateTime.UtcNow)
                .OrderByDescending(t => t.DatumKreiranja)
                .ToListAsync();

            var token = candidates.FirstOrDefault(t => VerifyResetCode(request.Kod, t.KodHash));
            if (token == null)
                throw new ValidationException(GenericInvalidCodeMessage);

            user.LozinkaHash = KorisnikService.HashPassword(request.NovaLozinka);
            user.LozinkaSalt = string.Empty;
            // Same as ChangeMyPassword/Update/Delete in KorisnikService: a password change must
            // invalidate every JWT issued before it (see Program.cs OnTokenValidated). The
            // forgot-password path is exactly when a compromised account gets its password
            // reset, so a stale token must not keep working here either.
            user.SigurnosniPecat = Guid.NewGuid();
            token.Iskoristen = true;

            var otherTokens = await _context.LozinkaResetTokens
                .Where(t => t.KorisnikId == user.KorisnikId && !t.Iskoristen && t.LozinkaResetTokenId != token.LozinkaResetTokenId)
                .ToListAsync();
            foreach (var other in otherTokens)
                other.Iskoristen = true;

            await _context.SaveChangesAsync();
            await tx.CommitAsync();
        }
        catch
        {
            await tx.RollbackAsync();
            throw;
        }
    }

    private static string GenerateResetCode()
        => RandomNumberGenerator.GetInt32(0, 1_000_000).ToString("D6");

    // Reset codes are hashed with bcrypt (same family as the account password hash) - never a bare
    // digest. The code space is small, so the real protections against guessing are the 30-minute
    // expiry, single-use flag and the 3-per-15-minutes request rate limit; bcrypt just keeps a
    // leaked LozinkaResetToken row from yielding the plaintext code.
    private const int ResetCodeWorkFactor = 12;

    private static string HashResetCode(string code)
        => BCrypt.Net.BCrypt.HashPassword(code, workFactor: ResetCodeWorkFactor);

    private static bool VerifyResetCode(string code, string hash)
    {
        try
        {
            return BCrypt.Net.BCrypt.Verify(code, hash);
        }
        catch (BCrypt.Net.SaltParseException)
        {
            // A pre-existing row from before this hashing change (or any malformed value) simply
            // doesn't match - it must not throw out of the verify loop.
            return false;
        }
    }
}
