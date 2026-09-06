using System.Security.Claims;
using DogShelter.Model;
using DogShelter.Services.Exceptions;
using DogShelter.Services.Interfaces;
using DogShelter.Services.Services;
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

    private const int MaxBrojPreporuka = 50;

    [HttpGet("psi")]
    [Authorize]
    public async Task<List<Model.PreporuceniPas>> Psi([FromQuery] int? take)
    {
        // Recommendations are an end-user feature (mobile). An admin account has no meaningful
        // interaction history and the desktop has no UI for this - block it explicitly so the
        // endpoint isn't a stray way for admin activity to touch the recommender.
        if (User.IsInRole(RoleNames.Admin))
            throw new ForbiddenException("Preporuke nisu dostupne administratorskom nalogu.");

        var howMany = take ?? PreporukaService.DefaultBrojPreporuka;
        howMany = Math.Clamp(howMany, 1, MaxBrojPreporuka);
        return await _service.PreporuceniPsi(GetCurrentKorisnikId(), howMany);
    }

    private int GetCurrentKorisnikId()
    {
        var idClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!int.TryParse(idClaim, out var korisnikId))
            throw new ForbiddenException("Nije moguće identificirati korisnika.");
        return korisnikId;
    }
}
