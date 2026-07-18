using DogShelter.Model;
using DogShelter.Model.Requests;

namespace DogShelter.Services.Interfaces;

public interface IVolonterService
{
    Task<PagedResult<Model.Volonter>> Get(VolonterSearchRequest search);
    Task<Model.Volonter> GetById(int id);
    Task<Model.Volonter?> GetByKorisnikId(int korisnikId);
    Task<Model.Volonter> Insert(VolonterInsertRequest request);
    Task<Model.Volonter> Update(int id, VolonterUpdateRequest request);
}
