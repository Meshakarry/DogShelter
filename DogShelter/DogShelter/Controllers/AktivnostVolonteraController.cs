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
public class AktivnostVolonteraController : ControllerBase
{
    private readonly IAktivnostVolonteraService _service;
    private readonly IAuthorizationService _authorizationService;

    public AktivnostVolonteraController(IAktivnostVolonteraService service, IAuthorizationService authorizationService)
    {
        _service = service;
        _authorizationService = authorizationService;
    }

    [HttpGet]
    [Authorize(Roles = $"{RoleNames.Admin},{RoleNames.Volonter}")]
    public async Task<PagedResult<Model.AktivnostVolontera>> Get([FromQuery] AktivnostVolonteraSearchRequest search)
        => await _service.Get(search, GetCurrentKorisnikId(), User.IsInRole(RoleNames.Admin));

    [HttpGet("{ID:int}")]
    [Authorize(Roles = $"{RoleNames.Admin},{RoleNames.Volonter}")]
    public async Task<Model.AktivnostVolontera> GetById(int ID)
    {
        var aktivnost = await _service.GetById(ID);

        var authResult = await _authorizationService.AuthorizeAsync(User, aktivnost, "CanModifyAktivnostVolontera");
        if (!authResult.Succeeded)
            throw new ForbiddenException("Nemate pristup ovoj aktivnosti.");

        return aktivnost;
    }

    [HttpPost]
    [Authorize(Roles = $"{RoleNames.Admin},{RoleNames.Volonter}")]
    public async Task<Model.AktivnostVolontera> Insert([FromBody] AktivnostVolonteraInsertRequest request)
        => await _service.Insert(request, GetCurrentKorisnikId(), User.IsInRole(RoleNames.Admin));

    [HttpDelete("{ID:int}")]
    [Authorize(Roles = RoleNames.Admin)]
    public async Task<bool> Delete(int ID)
        => await _service.Delete(ID);

    private int GetCurrentKorisnikId()
    {
        var idClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!int.TryParse(idClaim, out var korisnikId))
            throw new ForbiddenException("Nije moguće identificirati korisnika.");
        return korisnikId;
    }
}
