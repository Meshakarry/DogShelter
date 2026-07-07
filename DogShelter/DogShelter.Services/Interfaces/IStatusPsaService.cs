using DogShelter.Model;
using DogShelter.Model.Requests;

namespace DogShelter.Services.Interfaces
{
    public interface IStatusPsaService : ICRUDService<StatusPsa, LookupSearchRequest, LookupUpsertRequest, LookupUpsertRequest> { }
}
