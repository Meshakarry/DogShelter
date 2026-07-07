using DogShelter.Model;
using DogShelter.Model.Requests;

namespace DogShelter.Services.Interfaces
{
    public interface IRasaService : ICRUDService<Rasa, RasaSearchRequest, RasaUpsertRequest, RasaUpsertRequest> { }
}
