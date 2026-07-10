using DogShelter.Model;
using DogShelter.Model.Requests;
using DogShelter.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace DogShelter.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class StatusPosjeteController : BaseCRUDController<StatusPosjete, LookupSearchRequest, LookupUpsertRequest, LookupUpsertRequest>
    {
        public StatusPosjeteController(IStatusPosjeteService service) : base(service) { }
    }
}
