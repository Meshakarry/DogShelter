using DogShelter.Model;
using DogShelter.Model.Requests;

namespace DogShelter.Services.Interfaces
{
    public interface IStatusZahtjevaService : ICRUDService<StatusZahtjeva, LookupSearchRequest, LookupUpsertRequest, LookupUpsertRequest> { }
}
