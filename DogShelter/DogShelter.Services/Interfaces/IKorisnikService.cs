using DogShelter.Model;
using DogShelter.Model.Requests;

namespace DogShelter.Services.Interfaces
{
    public interface IKorisnikService : ICRUDService<Korisnik, KorisnikSearchRequest, KorisnikInsertRequest, KorisnikUpdateRequest>
    {
        Task<Korisnik?> Authenticate(AuthenticationRequest request);
        Task<Korisnik> Register(RegisterRequest request);
        Task<Korisnik> UpdateMyProfile(int userId, KorisnikProfileUpdateRequest request);
    }
}
