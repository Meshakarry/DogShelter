using DogShelter.Model;
using DogShelter.Model.Requests;
using DogShelter.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace DogShelter.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class VelicinaPsaController : BaseCRUDController<VelicinaPsa, LookupSearchRequest, LookupUpsertRequest, LookupUpsertRequest>
    {
        public VelicinaPsaController(IVelicinaPsaService service) : base(service) { }
    }
}
