using System.Security.Claims;
using DogShelter.Services.Exceptions;
using DogShelter.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace DogShelter.Controllers;

[Route("api/[controller]")]
[ApiController]
public class PreporukaController : ControllerBase
{
    private readonly IPreporukaService _service;

    public PreporukaController(IPreporukaService service)
    {
        _service = service;
    }

    [HttpGet("psi")]
    [Authorize]
    public async Task<List<Model.PreporuceniPas>> Psi([FromQuery] int? take)
        => await _service.PreporuceniPsi(GetCurrentKorisnikId(), take ?? 5);

    private int GetCurrentKorisnikId()
    {
        var idClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!int.TryParse(idClaim, out var korisnikId))
            throw new ForbiddenException("Nije moguće identificirati korisnika.");
        return korisnikId;
    }
}
