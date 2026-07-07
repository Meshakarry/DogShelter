using DogShelter.Model;
using DogShelter.Model.Requests;

namespace DogShelter.Services.Interfaces
{
    public interface ITipDonacijeService : ICRUDService<TipDonacije, LookupSearchRequest, LookupUpsertRequest, LookupUpsertRequest> { }
}
