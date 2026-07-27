using DogShelter.Services.Exceptions;
using DogShelter.Services.Interfaces;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Stripe;

namespace DogShelter.Services.Services;

public class StripePaymentService : IStripePaymentService
{
    private readonly string _currency;
    private readonly ILogger<StripePaymentService> _logger;
    private readonly PaymentIntentService _paymentIntentService = new();
    private readonly RefundService _refundService = new();

    public StripePaymentService(IConfiguration configuration, ILogger<StripePaymentService> logger)
    {
        _currency = configuration["Stripe:Currency"] ?? "eur";
        _logger = logger;
    }

    public async Task<(string PaymentIntentId, string ClientSecret)> CreatePaymentIntentAsync(decimal amount, int donacijaId, int korisnikId)
    {
        var options = new PaymentIntentCreateOptions
        {
            Amount = ToSmallestUnit(amount),
            Currency = _currency,
            AutomaticPaymentMethods = new PaymentIntentAutomaticPaymentMethodsOptions { Enabled = true, AllowRedirects = "never" },
            Metadata = new Dictionary<string, string>
            {
                ["donacijaId"] = donacijaId.ToString(),
                ["korisnikId"] = korisnikId.ToString()
            }
        };

        try
        {
            var paymentIntent = await _paymentIntentService.CreateAsync(options);
            return (paymentIntent.Id, paymentIntent.ClientSecret);
        }
        catch (StripeException ex)
        {
            _logger.LogError(ex, "Stripe PaymentIntent creation failed for donacija {DonacijaId}", donacijaId);
            throw new BusinessException($"Greška prilikom kreiranja Stripe plaćanja: {ex.Message}");
        }
    }

    public async Task<PaymentIntent?> GetPaymentIntentAsync(string paymentIntentId)
    {
        try
        {
            return await _paymentIntentService.GetAsync(paymentIntentId);
        }
        catch (StripeException ex) when (ex.StripeError?.Code == "resource_missing")
        {
            // The stored id no longer resolves on Stripe's side (e.g. purged test data, or the
            // secret key changed since it was created) - treat as "nothing to reconcile" rather
            // than a hard failure, so callers can fall back to creating a fresh PaymentIntent.
            _logger.LogInformation("Stripe PaymentIntent {PaymentIntentId} no longer exists remotely.", paymentIntentId);
            return null;
        }
        catch (StripeException ex)
        {
            _logger.LogError(ex, "Stripe PaymentIntent lookup failed for {PaymentIntentId}", paymentIntentId);
            throw new BusinessException($"Greška prilikom dohvatanja Stripe plaćanja: {ex.Message}");
        }
    }

    public async Task TryCancelPaymentIntentAsync(string paymentIntentId)
    {
        try
        {
            await _paymentIntentService.CancelAsync(paymentIntentId);
        }
        catch (StripeException ex)
        {
            _logger.LogInformation(ex, "Could not cancel Stripe PaymentIntent {PaymentIntentId} (likely already succeeded/canceled) — caller will reconcile from remote status.", paymentIntentId);
        }
    }

    public async Task<string> RefundAsync(string paymentIntentId, long amountInCents)
    {
        try
        {
            var refund = await _refundService.CreateAsync(new RefundCreateOptions
            {
                PaymentIntent = paymentIntentId,
                Amount = amountInCents
            });
            return refund.Id;
        }
        catch (StripeException ex)
        {
            _logger.LogError(ex, "Stripe refund failed for PaymentIntent {PaymentIntentId}", paymentIntentId);
            throw new BusinessException($"Greška prilikom vraćanja sredstava: {ex.Message}");
        }
    }

    private static long ToSmallestUnit(decimal amount) => (long)Math.Round(amount * 100, MidpointRounding.AwayFromZero);
}
