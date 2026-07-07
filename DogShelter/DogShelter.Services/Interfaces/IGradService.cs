using DogShelter.Model;
using DogShelter.Model.Requests;

namespace DogShelter.Services.Interfaces
{
    public interface IGradService : ICRUDService<Grad, GradSearchRequest, GradUpsertRequest, GradUpsertRequest> { }
}
