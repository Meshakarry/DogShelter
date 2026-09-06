using System.Security.Claims;
using DogShelter.Model.Requests;
using DogShelter.Services.Exceptions;
using DogShelter.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace DogShelter.Controllers;

[Route("api/[controller]")]
[ApiController]
public class FavoritController : ControllerBase
{
    private readonly IFavoritService _service;

    public FavoritController(IFavoritService service)
    {
        _service = service;
    }

    [HttpGet("mine")]
    [Authorize]
    public async Task<List<Model.Favorit>> Mine() => await _service.GetMineAsync(GetCurrentKorisnikId());

    [HttpPost]
    [Authorize]
    public async Task<Model.Favorit> Add([FromBody] FavoritInsertRequest request)
        => await _service.AddAsync(GetCurrentKorisnikId(), request.PasId);

    [HttpDelete("{pasId:int}")]
    [Authorize]
    public async Task<IActionResult> Remove(int pasId)
    {
        await _service.RemoveAsync(GetCurrentKorisnikId(), pasId);
        return Ok();
    }

    private int GetCurrentKorisnikId()
    {
        var idClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!int.TryParse(idClaim, out var korisnikId))
            throw new ForbiddenException("Nije moguće identificirati korisnika.");
        return korisnikId;
    }
}
