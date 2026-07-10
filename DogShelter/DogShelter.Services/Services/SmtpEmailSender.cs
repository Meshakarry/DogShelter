using System.Net;
using System.Net.Mail;
using DogShelter.Services.Interfaces;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace DogShelter.Services.Services;

public class SmtpEmailSender : IEmailSender
{
    private readonly IConfiguration _config;
    private readonly ILogger<SmtpEmailSender> _logger;

    public SmtpEmailSender(IConfiguration config, ILogger<SmtpEmailSender> logger)
    {
        _config = config;
        _logger = logger;
    }

    public async Task SendAsync(string toEmail, string subject, string body)
    {
        var smtp = _config.GetSection("SMTP");
        var host = smtp["Host"];
        var port = int.TryParse(smtp["Port"], out var p) ? p : 587;
        var username = smtp["Username"];
        var password = smtp["Password"];
        var useSsl = !bool.TryParse(smtp["UseSsl"], out var ssl) || ssl;
        var senderName = smtp["SenderName"] ?? "DogShelter";

        if (string.IsNullOrWhiteSpace(host) || string.IsNullOrWhiteSpace(username))
        {
            _logger.LogWarning("SMTP not configured; skipping email send to {Email}.", toEmail);
            return;
        }

        using var client = new SmtpClient(host, port)
        {
            Credentials = new NetworkCredential(username, password),
            EnableSsl = useSsl
        };

        using var message = new MailMessage
        {
            From = new MailAddress(username, senderName),
            Subject = subject,
            Body = body,
            IsBodyHtml = false
        };
        message.To.Add(toEmail);

        await client.SendMailAsync(message);
    }
}
