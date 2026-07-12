using DogShelter.Model;
using DogShelter.Model.Requests;

namespace DogShelter.Services.Interfaces;

public interface IDonacijaService
{
    Task<PagedResult<Donacija>> Get(DonacijaSearchRequest search, int currentKorisnikId, bool isAdmin);
    Task<Donacija> GetById(int id);
    Task<DonacijaPaymentResponse> Insert(DonacijaInsertRequest request, int korisnikId);
    Task<DonacijaPaymentResponse> RetryPlacanje(int id, int callerKorisnikId, bool isAdmin);
    Task<Donacija> Potvrdi(int id, int adminKorisnikId);
    Task<Donacija> Odbij(int id, DonacijaOdbijRequest request, int adminKorisnikId);
    Task<Donacija> Refund(int id, DonacijaRefundRequest request, int adminKorisnikId);
    Task HandlePaymentSucceededAsync(string paymentIntentId);
    Task HandlePaymentFailedAsync(string paymentIntentId, string? reason);
}
