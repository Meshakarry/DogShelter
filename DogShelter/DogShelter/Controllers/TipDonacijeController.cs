using DogShelter.Model;
using DogShelter.Model.Requests;
using DogShelter.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace DogShelter.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class TipDonacijeController : BaseCRUDController<TipDonacije, LookupSearchRequest, LookupUpsertRequest, LookupUpsertRequest>
    {
        public TipDonacijeController(ITipDonacijeService service) : base(service) { }
    }
}
