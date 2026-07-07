using DogShelter.Model;
using DogShelter.Model.Requests;

namespace DogShelter.Services.Interfaces
{
    public interface IStatusPosjeteService : ICRUDService<StatusPosjete, LookupSearchRequest, LookupUpsertRequest, LookupUpsertRequest> { }
}
