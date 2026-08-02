using DogShelter.Model;
using DogShelter.Model.Requests;
using DogShelter.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace DogShelter.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class UlogaController : BaseCRUDController<Uloga, LookupSearchRequest, LookupUpsertRequest, LookupUpsertRequest>
    {
        public UlogaController(IUlogaService service) : base(service) { }
    }
}
