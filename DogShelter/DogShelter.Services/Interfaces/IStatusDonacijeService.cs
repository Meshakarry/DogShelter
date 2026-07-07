using DogShelter.Model;
using DogShelter.Model.Requests;

namespace DogShelter.Services.Interfaces
{
    public interface IStatusDonacijeService : ICRUDService<StatusDonacije, LookupSearchRequest, LookupUpsertRequest, LookupUpsertRequest> { }
}
