using DogShelter.Model;
using DogShelter.Model.Requests;

namespace DogShelter.Services.Interfaces
{
    public interface IVelicinaPsaService : ICRUDService<VelicinaPsa, LookupSearchRequest, LookupUpsertRequest, LookupUpsertRequest> { }
}
