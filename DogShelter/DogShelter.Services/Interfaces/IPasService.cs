using DogShelter.Model;
using DogShelter.Model.Requests;
using Microsoft.AspNetCore.Http;

namespace DogShelter.Services.Interfaces;

public interface IPasService
{
    Task<PagedResult<Model.PasListItem>> Get(PasSearchRequest search);
    Task<Model.Pas> GetById(int id);
    Task<bool> Delete(int id);
    Task<Model.Pas> InsertWithImage(PasInsertRequest request, IFormFile? cover);
    Task<Model.Pas> UpdateWithImage(int id, PasUpdateRequest request, IFormFile? cover);
    Task<Model.SlikaPsa> AddSlika(int pasId, IFormFile file, int redniBroj);
    Task<bool> RemoveSlika(int slikaId);
}
