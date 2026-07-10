using DogShelter.Model;
using DogShelter.Model.Requests;
using DogShelter.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace DogShelter.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class StatusPsaController : BaseCRUDController<StatusPsa, LookupSearchRequest, LookupUpsertRequest, LookupUpsertRequest>
    {
        public StatusPsaController(IStatusPsaService service) : base(service) { }
    }
}
