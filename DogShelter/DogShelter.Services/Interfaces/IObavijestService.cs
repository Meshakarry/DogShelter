using DogShelter.Model;
using DogShelter.Model.Requests;
using Microsoft.AspNetCore.Http;

namespace DogShelter.Services.Interfaces;

public interface IObavijestService
{
    Task<PagedResult<Model.ObavijestListItem>> Get(ObavijestSearchRequest search, bool isAdmin);
    Task<Model.Obavijest> GetById(int id, bool isAdmin);
    Task<Model.Obavijest> InsertWithImage(ObavijestInsertRequest request, int autorId, IFormFile? slika);
    Task<Model.Obavijest> UpdateWithImage(int id, ObavijestUpdateRequest request, IFormFile? slika);
    Task<bool> Delete(int id);
}
