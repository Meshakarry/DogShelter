using DogShelter.Model;
using DogShelter.Model.Requests;
using DogShelter.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace DogShelter.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class GradController : BaseCRUDController<Grad, GradSearchRequest, GradUpsertRequest, GradUpsertRequest>
    {
        public GradController(IGradService service) : base(service) { }

        [HttpGet]
        [AllowAnonymous]
        public override async Task<PagedResult<Grad>> Get([FromQuery] GradSearchRequest search)
            => await base.Get(search);

        [HttpGet("{ID:int}")]
        [AllowAnonymous]
        public override async Task<Grad> GetById(int ID)
            => await base.GetById(ID);
    }
}
