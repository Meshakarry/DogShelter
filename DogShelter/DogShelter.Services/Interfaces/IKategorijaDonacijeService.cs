using DogShelter.Model;
using DogShelter.Model.Requests;

namespace DogShelter.Services.Interfaces
{
    public interface IKategorijaDonacijeService : ICRUDService<KategorijaDonacije, LookupSearchRequest, KategorijaDonacijeUpsertRequest, KategorijaDonacijeUpsertRequest> { }
}
