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
public class PregledPsaController : ControllerBase
{
    private readonly IPregledPsaService _service;

    public PregledPsaController(IPregledPsaService service)
    {
        _service = service;
    }

    [HttpGet]
    [Authorize(Roles = "Admin")]
    public async Task<PagedResult<Model.PregledPsa>> Get([FromQuery] PregledPsaSearchRequest search)
        => await _service.Get(search);

    [HttpPost]
    [Authorize]
    public async Task<Model.PregledPsa> Create([FromBody] PregledPsaInsertRequest request)
    {
        var idClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!int.TryParse(idClaim, out var korisnikId))
            throw new ForbiddenException("Nije moguće identificirati korisnika.");

        return await _service.LogPregled(request.PasId, korisnikId);
    }
}
