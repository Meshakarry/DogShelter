using DogShelter.Model;
using DogShelter.Model.Requests;
using Microsoft.AspNetCore.Http;

namespace DogShelter.Services.Interfaces;

public interface IDogadjajService
{
    Task<PagedResult<Model.Dogadjaj>> Get(DogadjajSearchRequest search, bool isAdmin);
    Task<Model.Dogadjaj> GetById(int id, bool isAdmin);
    Task<Model.Dogadjaj> InsertWithImage(DogadjajInsertRequest request, IFormFile? slika);
    Task<Model.Dogadjaj> UpdateWithImage(int id, DogadjajUpdateRequest request, IFormFile? slika);
    Task<bool> Otkazi(int id);
}
