using DogShelter.Model;
using DogShelter.Model.Requests;
using DogShelter.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace DogShelter.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class TipAktivnostiController : BaseCRUDController<TipAktivnosti, LookupSearchRequest, LookupUpsertRequest, LookupUpsertRequest>
    {
        public TipAktivnostiController(ITipAktivnostiService service) : base(service) { }

        [HttpGet]
        [AllowAnonymous]
        public override async Task<PagedResult<TipAktivnosti>> Get([FromQuery] LookupSearchRequest search)
            => await base.Get(search);

        [HttpGet("{ID:int}")]
        [AllowAnonymous]
        public override async Task<TipAktivnosti> GetById(int ID)
            => await base.GetById(ID);
    }
}
