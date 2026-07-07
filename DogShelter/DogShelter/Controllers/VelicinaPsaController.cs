using DogShelter.Model;
using DogShelter.Model.Requests;
using DogShelter.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace DogShelter.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class VelicinaPsaController : BaseCRUDController<VelicinaPsa, LookupSearchRequest, LookupUpsertRequest, LookupUpsertRequest>
    {
        public VelicinaPsaController(IVelicinaPsaService service) : base(service) { }

        [HttpGet]
        [AllowAnonymous]
        public override async Task<PagedResult<VelicinaPsa>> Get([FromQuery] LookupSearchRequest search)
            => await base.Get(search);

        [HttpGet("{ID:int}")]
        [AllowAnonymous]
        public override async Task<VelicinaPsa> GetById(int ID)
            => await base.GetById(ID);
    }
}
