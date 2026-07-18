using DogShelter.Model;
using DogShelter.Model.Requests;

namespace DogShelter.Services.Interfaces;

public interface IAktivnostVolonteraService
{
    Task<PagedResult<Model.AktivnostVolontera>> Get(AktivnostVolonteraSearchRequest search, int callerKorisnikId, bool isAdmin);
    Task<Model.AktivnostVolontera> GetById(int id);
    Task<Model.AktivnostVolontera> Insert(AktivnostVolonteraInsertRequest request, int callerKorisnikId, bool isAdmin);
    Task<bool> Delete(int id);
}
