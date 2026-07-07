using DogShelter.Model;
using DogShelter.Model.Requests;

namespace DogShelter.Services.Interfaces
{
    public interface IBaseService<T, TSearch> where TSearch : PagedSearchRequest
    {
        Task<PagedResult<T>> Get(TSearch search);
        Task<T> GetById(int ID);
    }
}
