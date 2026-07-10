using DogShelter.Model;
using DogShelter.Model.Requests;
using DogShelter.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace DogShelter.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class RasaController : BaseCRUDController<Rasa, RasaSearchRequest, RasaUpsertRequest, RasaUpsertRequest>
    {
        public RasaController(IRasaService service) : base(service) { }
    }
}
