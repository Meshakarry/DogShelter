using DogShelter.Model;
using DogShelter.Model.Requests;
using DogShelter.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace DogShelter.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class KategorijaDonacijeController : BaseCRUDController<KategorijaDonacije, LookupSearchRequest, KategorijaDonacijeUpsertRequest, KategorijaDonacijeUpsertRequest>
    {
        public KategorijaDonacijeController(IKategorijaDonacijeService service) : base(service) { }
    }
}
