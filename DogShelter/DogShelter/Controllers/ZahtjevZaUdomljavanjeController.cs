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
public class ZahtjevZaUdomljavanjeController : ControllerBase
{
    private readonly IZahtjevZaUdomljavanjeService _service;
    private readonly IAuthorizationService _authorizationService;

    public ZahtjevZaUdomljavanjeController(IZahtjevZaUdomljavanjeService service, IAuthorizationService authorizationService)
    {
        _service = service;
        _authorizationService = authorizationService;
    }

    [HttpGet]
    [Authorize]
    public async Task<PagedResult<ZahtjevZaUdomljavanje>> Get([FromQuery] ZahtjevZaUdomljavanjeSearchRequest search)
        => await _service.Get(search, GetCurrentKorisnikId(), User.IsInRole("Admin"));

    [HttpGet("{ID:int}")]
    [Authorize]
    public async Task<ZahtjevZaUdomljavanje> GetById(int ID)
    {
        var zahtjev = await _service.GetById(ID);

        var authResult = await _authorizationService.AuthorizeAsync(User, zahtjev, "CanModifyZahtjev");
        if (!authResult.Succeeded)
            throw new ForbiddenException("Nemate pristup ovom zahtjevu.");

        return zahtjev;
    }

    [HttpPost]
    [Authorize]
    public async Task<ZahtjevZaUdomljavanje> Insert([FromBody] ZahtjevZaUdomljavanjeInsertRequest request)
        => await _service.Insert(request, GetCurrentKorisnikId());

    [HttpPost("{ID:int}/odobri")]
    [Authorize(Roles = RoleNames.Admin)]
    public async Task<ZahtjevZaUdomljavanje> Odobri(int ID)
        => await _service.Odobri(ID, GetCurrentKorisnikId());

    [HttpPost("{ID:int}/odbij")]
    [Authorize(Roles = RoleNames.Admin)]
    public async Task<ZahtjevZaUdomljavanje> Odbij(int ID, [FromBody] ZahtjevZaUdomljavanjeOdbijRequest request)
        => await _service.Odbij(ID, request, GetCurrentKorisnikId());

    [HttpPost("{ID:int}/otkazi")]
    [Authorize]
    public async Task<ZahtjevZaUdomljavanje> Otkazi(int ID, [FromBody] ZahtjevZaUdomljavanjeOtkaziRequest request)
        => await _service.Otkazi(ID, request, GetCurrentKorisnikId(), User.IsInRole(RoleNames.Admin));

    private int GetCurrentKorisnikId()
    {
        var idClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!int.TryParse(idClaim, out var korisnikId))
            throw new ForbiddenException("Nije moguće identificirati korisnika.");
        return korisnikId;
    }
}
