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
[Authorize]
public class NotifikacijaController : ControllerBase
{
    private readonly INotifikacijaService _service;

    public NotifikacijaController(INotifikacijaService service)
    {
        _service = service;
    }

    [HttpGet]
    public async Task<PagedResult<Model.Notifikacija>> Get([FromQuery] NotifikacijaSearchRequest search)
        => await _service.Get(search, GetCurrentKorisnikId());

    [HttpGet("broj-neprocitanih")]
    public async Task<int> GetUnreadCount()
        => await _service.GetUnreadCount(GetCurrentKorisnikId());

    [HttpPost("{ID:int}/procitaj")]
    public async Task<bool> OznaciProcitano(int ID)
        => await _service.OznaciProcitano(GetCurrentKorisnikId(), ID)
            ? true
            : throw new NotFoundException($"Notifikacija s ID {ID} nije pronađena.");

    [HttpPost("procitaj-sve")]
    public async Task<bool> OznaciSveProcitano()
    {
        await _service.OznaciSveProcitano(GetCurrentKorisnikId());
        return true;
    }

    private int GetCurrentKorisnikId()
    {
        var idClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!int.TryParse(idClaim, out var korisnikId))
            throw new ForbiddenException("Nije moguće identificirati korisnika.");
        return korisnikId;
    }
}
