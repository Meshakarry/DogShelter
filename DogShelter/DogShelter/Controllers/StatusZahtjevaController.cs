using DogShelter.Model;
using DogShelter.Model.Requests;
using DogShelter.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace DogShelter.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class StatusZahtjevaController : BaseCRUDController<StatusZahtjeva, LookupSearchRequest, LookupUpsertRequest, LookupUpsertRequest>
    {
        public StatusZahtjevaController(IStatusZahtjevaService service) : base(service) { }
    }
}
