using DogShelter.Model;
using DogShelter.Model.Requests;

namespace DogShelter.Services.Interfaces;

public interface IPotrebaAzilaService
{
    Task<PagedResult<PotrebaAzila>> Get(PotrebaAzilaSearchRequest search, bool isAdmin);
    Task<PotrebaAzila> GetById(int id);
    Task<PotrebaAzila> Insert(PotrebaAzilaInsertRequest request);
    Task<PotrebaAzila> Update(int id, PotrebaAzilaUpdateRequest request);
    Task<bool> Delete(int id);
}
