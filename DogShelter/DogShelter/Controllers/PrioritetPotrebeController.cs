using DogShelter.Model;
using DogShelter.Model.Requests;
using DogShelter.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace DogShelter.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class PrioritetPotrebeController : BaseCRUDController<PrioritetPotrebe, LookupSearchRequest, LookupUpsertRequest, LookupUpsertRequest>
    {
        public PrioritetPotrebeController(IPrioritetPotrebeService service) : base(service) { }
    }
}
