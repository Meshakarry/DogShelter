using DogShelter.Model;
using DogShelter.Model.Requests;
using DogShelter.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace DogShelter.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class StatusZahtjevaController : BaseCRUDController<StatusZahtjeva, LookupSearchRequest, LookupUpsertRequest, LookupUpsertRequest>
    {
        public StatusZahtjevaController(IStatusZahtjevaService service) : base(service) { }

        [HttpGet]
        [AllowAnonymous]
        public override async Task<PagedResult<StatusZahtjeva>> Get([FromQuery] LookupSearchRequest search)
            => await base.Get(search);

        [HttpGet("{ID:int}")]
        [AllowAnonymous]
        public override async Task<StatusZahtjeva> GetById(int ID)
            => await base.GetById(ID);
    }
}
