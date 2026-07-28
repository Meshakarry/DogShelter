using DogShelter.Model;
using DogShelter.Model.Requests;
using DogShelter.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace DogShelter.Controllers;

[Route("api/[controller]")]
[ApiController]
public class PotrebaAzilaController : ControllerBase
{
    private readonly IPotrebaAzilaService _service;

    public PotrebaAzilaController(IPotrebaAzilaService service)
    {
        _service = service;
    }

    [HttpGet]
    [Authorize]
    public async Task<PagedResult<PotrebaAzila>> Get([FromQuery] PotrebaAzilaSearchRequest search)
        => await _service.Get(search, User.IsInRole("Admin"));

    [HttpGet("{ID:int}")]
    [Authorize]
    public async Task<PotrebaAzila> GetById(int ID)
        => await _service.GetById(ID);

    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<PotrebaAzila> Insert([FromBody] PotrebaAzilaInsertRequest request)
        => await _service.Insert(request);

    [HttpPut("{ID:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<PotrebaAzila> Update(int ID, [FromBody] PotrebaAzilaUpdateRequest request)
        => await _service.Update(ID, request);

    [HttpDelete("{ID:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<bool> Delete(int ID)
        => await _service.Delete(ID);
}
