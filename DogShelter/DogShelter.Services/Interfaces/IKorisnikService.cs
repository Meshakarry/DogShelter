using DogShelter.Model;
using DogShelter.Model.Requests;
using Microsoft.AspNetCore.Http;

namespace DogShelter.Services.Interfaces
{
    public interface IKorisnikService : ICRUDService<Korisnik, KorisnikSearchRequest, KorisnikInsertRequest, KorisnikUpdateRequest>
    {
        Task<Korisnik?> Authenticate(AuthenticationRequest request);
        Task<Korisnik> Register(RegisterRequest request);
        Task<Korisnik> UpdateMyProfile(int userId, KorisnikProfileUpdateRequest request);
        Task ChangeMyPassword(int userId, KorisnikChangePasswordRequest request);
        Task<Korisnik> UpdateMyAvatar(int userId, IFormFile file);
        Task<(string FullPath, string ContentType)> GetAvatarFileAsync(int id, int callerId, bool isAdmin);
    }
}
