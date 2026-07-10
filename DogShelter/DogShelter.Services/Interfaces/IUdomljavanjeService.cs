using DogShelter.Model;
using DogShelter.Model.Requests;

namespace DogShelter.Services.Interfaces;

public interface IUdomljavanjeService
{
    Task<PagedResult<Udomljavanje>> Get(UdomljavanjeSearchRequest search, int currentKorisnikId, bool isAdmin);
    Task<Udomljavanje> GetById(int id, int currentKorisnikId, bool isAdmin);
}
