using DogShelter.Model;
using DogShelter.Model.Requests;

namespace DogShelter.Services.Interfaces;

public interface IDogadjajVolonterService
{
    Task<PagedResult<Model.DogadjajVolonter>> Get(DogadjajVolonterSearchRequest search, int callerKorisnikId, bool isAdmin);
    Task<Model.DogadjajVolonter> Zaduzi(DogadjajVolonterInsertRequest request);
    Task<bool> Ukloni(int id);
}
