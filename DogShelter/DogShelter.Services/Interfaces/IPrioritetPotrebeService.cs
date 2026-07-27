using DogShelter.Model;
using DogShelter.Model.Requests;

namespace DogShelter.Services.Interfaces
{
    public interface IPrioritetPotrebeService : ICRUDService<PrioritetPotrebe, LookupSearchRequest, LookupUpsertRequest, LookupUpsertRequest> { }
}
