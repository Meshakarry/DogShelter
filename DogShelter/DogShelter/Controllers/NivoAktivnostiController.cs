using DogShelter.Model;
using DogShelter.Model.Requests;
using DogShelter.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace DogShelter.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class NivoAktivnostiController : BaseCRUDController<NivoAktivnosti, LookupSearchRequest, LookupUpsertRequest, LookupUpsertRequest>
    {
        public NivoAktivnostiController(INivoAktivnostiService service) : base(service) { }
    }
}
