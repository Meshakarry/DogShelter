using DogShelter.Model;
using DogShelter.Model.Requests;

namespace DogShelter.Services.Interfaces
{
    public interface INivoAktivnostiService : ICRUDService<NivoAktivnosti, LookupSearchRequest, LookupUpsertRequest, LookupUpsertRequest> { }
}
