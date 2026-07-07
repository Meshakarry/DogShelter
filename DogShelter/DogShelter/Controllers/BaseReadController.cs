using DogShelter.Model;
using DogShelter.Model.Requests;
using DogShelter.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace DogShelter.Controllers
{
    [Route("api/[controller]")]
    [ApiController]

    public class BaseReadController<T, Tsearch> : ControllerBase where Tsearch : PagedSearchRequest
    {
        private readonly IBaseService<T, Tsearch> _service;
        public BaseReadController(IBaseService<T, Tsearch> service)
        {
            _service = service;
        }

        [HttpGet]
        [Authorize]
        public virtual async Task<PagedResult<T>> Get([FromQuery] Tsearch search)
        {
            return await _service.Get(search);
        }
        [HttpGet("{ID:int}")]
        [Authorize]
        public virtual async Task<T> GetById(int ID)
        {
            return await _service.GetById(ID);
        }
    }
}
