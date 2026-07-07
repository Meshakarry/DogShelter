using DogShelter.Model;
using DogShelter.Model.Requests;
using DogShelter.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace DogShelter.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class StatusDonacijeController : BaseCRUDController<StatusDonacije, LookupSearchRequest, LookupUpsertRequest, LookupUpsertRequest>
    {
        public StatusDonacijeController(IStatusDonacijeService service) : base(service) { }

        [HttpGet]
        [AllowAnonymous]
        public override async Task<PagedResult<StatusDonacije>> Get([FromQuery] LookupSearchRequest search)
            => await base.Get(search);

        [HttpGet("{ID:int}")]
        [AllowAnonymous]
        public override async Task<StatusDonacije> GetById(int ID)
            => await base.GetById(ID);
    }
}
