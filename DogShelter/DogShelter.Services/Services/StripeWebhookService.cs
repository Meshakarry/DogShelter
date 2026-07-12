using DogShelter.Services.Interfaces;
using Microsoft.Extensions.Configuration;
using Stripe;

namespace DogShelter.Services.Services;

public class StripeWebhookService : IStripeWebhookService
{
    private readonly IDonacijaService _donacijaService;
    private readonly string _webhookSecret;

    public StripeWebhookService(IDonacijaService donacijaService, IConfiguration configuration)
    {
        _donacijaService = donacijaService;
        _webhookSecret = configuration["Stripe:WebhookSecret"] ?? string.Empty;
    }

    public async Task ProcessWebhookAsync(string json, string signatureHeader)
    {
        var stripeEvent = EventUtility.ConstructEvent(json, signatureHeader, _webhookSecret, throwOnApiVersionMismatch: false);

        if (stripeEvent.Data.Object is not PaymentIntent paymentIntent)
            return;

        if (stripeEvent.Type == "payment_intent.succeeded")
        {
            await _donacijaService.HandlePaymentSucceededAsync(paymentIntent.Id);
        }
        else if (stripeEvent.Type == "payment_intent.payment_failed")
        {
            await _donacijaService.HandlePaymentFailedAsync(paymentIntent.Id, paymentIntent.LastPaymentError?.Message);
        }
    }
}
