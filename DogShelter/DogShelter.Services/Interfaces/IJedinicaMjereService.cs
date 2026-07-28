using DogShelter.Model;
using DogShelter.Model.Requests;

namespace DogShelter.Services.Interfaces
{
    public interface IJedinicaMjereService : ICRUDService<JedinicaMjere, LookupSearchRequest, LookupUpsertRequest, LookupUpsertRequest> { }
}
