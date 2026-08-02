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
public class DonacijaController : ControllerBase
{
    private readonly IDonacijaService _service;
    private readonly IAuthorizationService _authorizationService;

    public DonacijaController(IDonacijaService service, IAuthorizationService authorizationService)
    {
        _service = service;
        _authorizationService = authorizationService;
    }

    [HttpGet]
    [Authorize]
    public async Task<PagedResult<Donacija>> Get([FromQuery] DonacijaSearchRequest search)
        => await _service.Get(search, GetCurrentKorisnikId(), User.IsInRole("Admin"));

    [HttpGet("{ID:int}")]
    [Authorize]
    public async Task<Donacija> GetById(int ID)
    {
        var donacija = await _service.GetById(ID);

        var authResult = await _authorizationService.AuthorizeAsync(User, donacija, "CanModifyDonacija");
        if (!authResult.Succeeded)
            throw new ForbiddenException("Nemate pristup ovoj donaciji.");

        return donacija;
    }

    [HttpPost]
    [Authorize]
    public async Task<DonacijaPaymentResponse> Insert([FromBody] DonacijaInsertRequest request)
        => await _service.Insert(request, GetCurrentKorisnikId());

    [HttpPost("{ID:int}/retry-placanje")]
    [Authorize]
    public async Task<DonacijaPaymentResponse> RetryPlacanje(int ID)
        => await _service.RetryPlacanje(ID, GetCurrentKorisnikId(), User.IsInRole("Admin"));

    [HttpPost("{ID:int}/potvrdi")]
    [Authorize(Roles = RoleNames.Admin)]
    public async Task<Donacija> Potvrdi(int ID)
        => await _service.Potvrdi(ID, GetCurrentKorisnikId());

    [HttpPost("{ID:int}/odbij")]
    [Authorize(Roles = RoleNames.Admin)]
    public async Task<Donacija> Odbij(int ID, [FromBody] DonacijaOdbijRequest request)
        => await _service.Odbij(ID, request, GetCurrentKorisnikId());

    [HttpPost("{ID:int}/refund")]
    [Authorize(Roles = RoleNames.Admin)]
    public async Task<Donacija> Refund(int ID, [FromBody] DonacijaRefundRequest request)
        => await _service.Refund(ID, request, GetCurrentKorisnikId());

    [HttpGet("report")]
    [Authorize(Roles = RoleNames.Admin)]
    public async Task<DonacijaIzvjestaj> Report([FromQuery] IzvjestajRequest request)
        => await _service.GenerirajIzvjestaj(request.DatumOd, request.DatumDo);

    private int GetCurrentKorisnikId()
    {
        var idClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!int.TryParse(idClaim, out var korisnikId))
            throw new ForbiddenException("Nije moguće identificirati korisnika.");
        return korisnikId;
    }
}
