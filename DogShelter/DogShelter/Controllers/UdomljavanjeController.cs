using System.Security.Claims;
using DogShelter.Model;
using DogShelter.Model.Reports;
using DogShelter.Model.Requests;
using DogShelter.Services.Exceptions;
using DogShelter.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace DogShelter.Controllers;

[Route("api/[controller]")]
[ApiController]
public class UdomljavanjeController : ControllerBase
{
    private readonly IUdomljavanjeService _service;

    public UdomljavanjeController(IUdomljavanjeService service)
    {
        _service = service;
    }

    [HttpGet]
    [Authorize]
    public async Task<PagedResult<Udomljavanje>> Get([FromQuery] UdomljavanjeSearchRequest search)
        => await _service.Get(search, GetCurrentKorisnikId(), User.IsInRole("Admin"));

    [HttpGet("{ID:int}")]
    [Authorize]
    public async Task<Udomljavanje> GetById(int ID)
        => await _service.GetById(ID, GetCurrentKorisnikId(), User.IsInRole("Admin"));

    [HttpGet("report")]
    [Authorize(Roles = "Admin")]
    public async Task<UdomljavanjeIzvjestaj> Report([FromQuery] IzvjestajRequest request)
        => await _service.GenerirajIzvjestaj(request.DatumOd, request.DatumDo);

    private int GetCurrentKorisnikId()
    {
        var idClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!int.TryParse(idClaim, out var korisnikId))
            throw new ForbiddenException("Nije moguće identificirati korisnika.");
        return korisnikId;
    }
}
