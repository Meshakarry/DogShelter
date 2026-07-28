using DogShelter.Model;
using DogShelter.Model.Requests;
using DogShelter.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace DogShelter.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class JedinicaMjereController : BaseCRUDController<JedinicaMjere, LookupSearchRequest, LookupUpsertRequest, LookupUpsertRequest>
    {
        public JedinicaMjereController(IJedinicaMjereService service) : base(service) { }
    }
}
