using DogShelter.Model;
using DogShelter.Model.Requests;
using DogShelter.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace DogShelter.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class RasaController : BaseCRUDController<Rasa, RasaSearchRequest, RasaUpsertRequest, RasaUpsertRequest>
    {
        public RasaController(IRasaService service) : base(service) { }

        [HttpGet]
        [AllowAnonymous]
        public override async Task<PagedResult<Rasa>> Get([FromQuery] RasaSearchRequest search)
            => await base.Get(search);

        [HttpGet("{ID:int}")]
        [AllowAnonymous]
        public override async Task<Rasa> GetById(int ID)
            => await base.GetById(ID);
    }
}
