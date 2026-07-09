using DogShelter.Model.Requests;
using DogShelter.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace DogShelter.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class BaseCRUDController<T, TSearch, TInsert, TUpdate> : BaseReadController<T, TSearch>
        where TSearch : PagedSearchRequest
    {
        private readonly ICRUDService<T, TSearch, TInsert, TUpdate> _service;
        public BaseCRUDController(ICRUDService<T, TSearch, TInsert, TUpdate> service) : base(service)
        {
            _service = service;
        }

        [HttpPost]
        [Authorize(Roles = "Admin")]
        public virtual async Task<T> Insert(TInsert request)
        {
            return await _service.Insert(request);
        }

        [HttpPut("{ID:int}")]
        [Authorize(Roles = "Admin")]
        public virtual async Task<T> Update(int ID, TUpdate request)
        {
            return await _service.Update(ID, request);
        }

        [HttpDelete("{ID:int}")]
        [Authorize(Roles = "Admin")]
        public virtual async Task<bool> Delete(int ID)
        {
            return await _service.Delete(ID);
        }
    }
}
