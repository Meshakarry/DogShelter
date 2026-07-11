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
public class PosjetaController : ControllerBase
{
    private readonly IPosjetaService _service;
    private readonly IAuthorizationService _authorizationService;

    public PosjetaController(IPosjetaService service, IAuthorizationService authorizationService)
    {
        _service = service;
        _authorizationService = authorizationService;
    }

    [HttpGet]
    [Authorize]
    public async Task<PagedResult<Posjeta>> Get([FromQuery] PosjetaSearchRequest search)
        => await _service.Get(search, GetCurrentKorisnikId(), User.IsInRole("Admin"));

    [HttpGet("{ID:int}")]
    [Authorize]
    public async Task<Posjeta> GetById(int ID)
    {
        var posjeta = await _service.GetById(ID);

        var authResult = await _authorizationService.AuthorizeAsync(User, posjeta, "CanModifyPosjeta");
        if (!authResult.Succeeded)
            throw new ForbiddenException("Nemate pristup ovoj posjeti.");

        return posjeta;
    }

    [HttpPost]
    [Authorize]
    public async Task<Posjeta> Insert([FromBody] PosjetaInsertRequest request)
        => await _service.Insert(request, GetCurrentKorisnikId());

    [HttpPost("admin")]
    [Authorize(Roles = "Admin")]
    public async Task<Posjeta> InsertAdmin([FromBody] PosjetaAdminInsertRequest request)
        => await _service.InsertAdmin(request, GetCurrentKorisnikId());

    [HttpPost("{ID:int}/potvrdi")]
    [Authorize(Roles = "Admin")]
    public async Task<Posjeta> Potvrdi(int ID)
        => await _service.Potvrdi(ID, GetCurrentKorisnikId());

    [HttpPost("{ID:int}/otkazi")]
    [Authorize]
    public async Task<Posjeta> Otkazi(int ID, [FromBody] PosjetaOtkaziRequest request)
        => await _service.Otkazi(ID, request, GetCurrentKorisnikId(), User.IsInRole("Admin"));

    [HttpPost("{ID:int}/zavrsi")]
    [Authorize(Roles = "Admin")]
    public async Task<Posjeta> Zavrsi(int ID)
        => await _service.Zavrsi(ID, GetCurrentKorisnikId());

    private int GetCurrentKorisnikId()
    {
        var idClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!int.TryParse(idClaim, out var korisnikId))
            throw new ForbiddenException("Nije moguće identificirati korisnika.");
        return korisnikId;
    }
}
