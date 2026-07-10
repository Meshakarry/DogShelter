using DogShelter.Model;
using DogShelter.Model.Requests;
using DogShelter.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace DogShelter.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class StatusDonacijeController : BaseCRUDController<StatusDonacije, LookupSearchRequest, LookupUpsertRequest, LookupUpsertRequest>
    {
        public StatusDonacijeController(IStatusDonacijeService service) : base(service) { }
    }
}
