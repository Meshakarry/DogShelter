using DogShelter.Model;
using DogShelter.Model.Requests;
using DogShelter.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace DogShelter.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class GradController : BaseCRUDController<Grad, GradSearchRequest, GradUpsertRequest, GradUpsertRequest>
    {
        public GradController(IGradService service) : base(service) { }
    }
}
