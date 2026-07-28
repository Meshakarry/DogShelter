using Stripe;

namespace DogShelter.Services.Interfaces;

public interface IStripePaymentService
{
    Task<(string PaymentIntentId, string ClientSecret)> CreatePaymentIntentAsync(decimal amount, int donacijaId, int korisnikId);
    Task<PaymentIntent?> GetPaymentIntentAsync(string paymentIntentId);
    Task TryCancelPaymentIntentAsync(string paymentIntentId);
    Task<string> RefundAsync(string paymentIntentId, long amountInCents);
}
