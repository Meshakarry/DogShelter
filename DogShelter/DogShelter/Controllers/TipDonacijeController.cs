using DogShelter.Model;
using DogShelter.Model.Requests;
using DogShelter.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace DogShelter.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class TipDonacijeController : BaseCRUDController<TipDonacije, LookupSearchRequest, LookupUpsertRequest, LookupUpsertRequest>
    {
        public TipDonacijeController(ITipDonacijeService service) : base(service) { }

        [HttpGet]
        [AllowAnonymous]
        public override async Task<PagedResult<TipDonacije>> Get([FromQuery] LookupSearchRequest search)
            => await base.Get(search);

        [HttpGet("{ID:int}")]
        [AllowAnonymous]
        public override async Task<TipDonacije> GetById(int ID)
            => await base.GetById(ID);
    }
}
