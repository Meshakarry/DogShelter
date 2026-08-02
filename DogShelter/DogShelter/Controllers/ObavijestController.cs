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
public class ObavijestController : ControllerBase
{
    private readonly IObavijestService _obavijestService;

    public ObavijestController(IObavijestService obavijestService)
    {
        _obavijestService = obavijestService;
    }

    [HttpGet]
    [Authorize]
    public async Task<PagedResult<Model.ObavijestListItem>> Get([FromQuery] ObavijestSearchRequest search)
        => await _obavijestService.Get(search, User.IsInRole("Admin"));

    [HttpGet("{ID:int}")]
    [Authorize]
    public async Task<Model.Obavijest> GetById(int ID)
        => await _obavijestService.GetById(ID, User.IsInRole("Admin"));

    [HttpPost]
    [Authorize(Roles = RoleNames.Admin)]
    [Consumes("multipart/form-data")]
    public async Task<Model.Obavijest> Insert([FromForm] ObavijestInsertRequest request)
    {
        var idClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!int.TryParse(idClaim, out var autorId))
            throw new ForbiddenException("Nije moguće identificirati korisnika.");

        var slika = Request.Form.Files.GetFile("slika");
        return await _obavijestService.InsertWithImage(request, autorId, slika);
    }

    [HttpPut("{ID:int}")]
    [Authorize(Roles = RoleNames.Admin)]
    [Consumes("multipart/form-data")]
    public async Task<Model.Obavijest> Update(int ID, [FromForm] ObavijestUpdateRequest request)
    {
        var slika = Request.Form.Files.GetFile("slika");
        return await _obavijestService.UpdateWithImage(ID, request, slika);
    }

    [HttpDelete("{ID:int}")]
    [Authorize(Roles = RoleNames.Admin)]
    public async Task<bool> Delete(int ID)
        => await _obavijestService.Delete(ID);
}
