using DogShelter.Model;
using DogShelter.Model.Requests;

namespace DogShelter.Services.Interfaces
{
    public interface IUlogaService : ICRUDService<Uloga, LookupSearchRequest, LookupUpsertRequest, LookupUpsertRequest> { }
}
