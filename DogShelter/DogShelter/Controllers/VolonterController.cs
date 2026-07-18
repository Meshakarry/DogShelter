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
public class VolonterController : ControllerBase
{
    private readonly IVolonterService _service;
    private readonly IAuthorizationService _authorizationService;

    public VolonterController(IVolonterService service, IAuthorizationService authorizationService)
    {
        _service = service;
        _authorizationService = authorizationService;
    }

    [HttpGet]
    [Authorize(Roles = RoleNames.Admin)]
    public async Task<PagedResult<Model.Volonter>> Get([FromQuery] VolonterSearchRequest search)
        => await _service.Get(search);

    [HttpGet("me")]
    [Authorize(Roles = RoleNames.Volonter)]
    public async Task<Model.Volonter> GetMe()
    {
        var volonter = await _service.GetByKorisnikId(GetCurrentKorisnikId())
            ?? throw new NotFoundException("Nemate evidentiran volonterski profil.");
        return volonter;
    }

    [HttpGet("{ID:int}")]
    [Authorize]
    public async Task<Model.Volonter> GetById(int ID)
    {
        var volonter = await _service.GetById(ID);

        var authResult = await _authorizationService.AuthorizeAsync(User, volonter, "CanModifyVolonter");
        if (!authResult.Succeeded)
            throw new ForbiddenException("Nemate pristup ovom volonterskom profilu.");

        return volonter;
    }

    [HttpPost]
    [Authorize(Roles = RoleNames.Admin)]
    public async Task<Model.Volonter> Insert([FromBody] VolonterInsertRequest request)
        => await _service.Insert(request);

    [HttpPut("{ID:int}")]
    [Authorize(Roles = RoleNames.Admin)]
    public async Task<Model.Volonter> Update(int ID, [FromBody] VolonterUpdateRequest request)
        => await _service.Update(ID, request);

    private int GetCurrentKorisnikId()
    {
        var idClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!int.TryParse(idClaim, out var korisnikId))
            throw new ForbiddenException("Nije moguće identificirati korisnika.");
        return korisnikId;
    }
}
