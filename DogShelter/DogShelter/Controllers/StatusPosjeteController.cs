using DogShelter.Model;
using DogShelter.Model.Requests;
using DogShelter.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace DogShelter.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class StatusPosjeteController : BaseCRUDController<StatusPosjete, LookupSearchRequest, LookupUpsertRequest, LookupUpsertRequest>
    {
        public StatusPosjeteController(IStatusPosjeteService service) : base(service) { }

        [HttpGet]
        [AllowAnonymous]
        public override async Task<PagedResult<StatusPosjete>> Get([FromQuery] LookupSearchRequest search)
            => await base.Get(search);

        [HttpGet("{ID:int}")]
        [AllowAnonymous]
        public override async Task<StatusPosjete> GetById(int ID)
            => await base.GetById(ID);
    }
}
