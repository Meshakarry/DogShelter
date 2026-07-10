using DogShelter.Model;
using DogShelter.Model.Requests;
using DogShelter.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace DogShelter.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class TipAktivnostiController : BaseCRUDController<TipAktivnosti, LookupSearchRequest, LookupUpsertRequest, LookupUpsertRequest>
    {
        public TipAktivnostiController(ITipAktivnostiService service) : base(service) { }
    }
}
