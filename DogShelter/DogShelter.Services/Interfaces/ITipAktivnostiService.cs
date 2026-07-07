using DogShelter.Model;
using DogShelter.Model.Requests;

namespace DogShelter.Services.Interfaces
{
    public interface ITipAktivnostiService : ICRUDService<TipAktivnosti, LookupSearchRequest, LookupUpsertRequest, LookupUpsertRequest> { }
}
