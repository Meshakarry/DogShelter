using System.Security.Claims;
using DogShelter.Model;
using DogShelter.Model.Requests;
using DogShelter.Services.Exceptions;
using DogShelter.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace DogShelter.Controllers;

[Route("api/[controller]")]
[ApiController]
public class DogadjajVolonterController : ControllerBase
{
    private readonly IDogadjajVolonterService _service;

    public DogadjajVolonterController(IDogadjajVolonterService service)
    {
        _service = service;
    }

    [HttpGet]
    [Authorize(Roles = $"{RoleNames.Admin},{RoleNames.Volonter}")]
    public async Task<PagedResult<Model.DogadjajVolonter>> Get([FromQuery] DogadjajVolonterSearchRequest search)
        => await _service.Get(search, GetCurrentKorisnikId(), User.IsInRole(RoleNames.Admin));

    [HttpPost("zaduzi")]
    [Authorize(Roles = RoleNames.Admin)]
    public async Task<Model.DogadjajVolonter> Zaduzi([FromBody] DogadjajVolonterInsertRequest request)
        => await _service.Zaduzi(request);

    [HttpDelete("{ID:int}")]
    [Authorize(Roles = RoleNames.Admin)]
    public async Task<bool> Ukloni(int ID)
        => await _service.Ukloni(ID);

    private int GetCurrentKorisnikId()
    {
        var idClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!int.TryParse(idClaim, out var korisnikId))
            throw new ForbiddenException("Nije moguće identificirati korisnika.");
        return korisnikId;
    }
}
