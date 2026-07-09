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
public class PasController : ControllerBase
{
    private readonly IPasService _pasService;
    private readonly IPregledPsaService _pregledService;

    public PasController(IPasService pasService, IPregledPsaService pregledService)
    {
        _pasService = pasService;
        _pregledService = pregledService;
    }

    [HttpGet]
    [Authorize]
    public async Task<PagedResult<Model.PasListItem>> Get([FromQuery] PasSearchRequest search)
        => await _pasService.Get(search);

    [HttpGet("{ID:int}")]
    [Authorize]
    public async Task<Model.Pas> GetById(int ID)
    {
        var pas = await _pasService.GetById(ID);

        var idClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!int.TryParse(idClaim, out var korisnikId))
            throw new ForbiddenException("Nije moguće identificirati korisnika.");

        try { await _pregledService.LogPregled(ID, korisnikId); }
        catch { /* log failure must never break a dog read */ }

        return pas;
    }

    [HttpPost]
    [Authorize(Roles = "Admin")]
    [Consumes("multipart/form-data")]
    public async Task<Model.Pas> Insert([FromForm] PasInsertRequest request)
    {
        var cover = Request.Form.Files.GetFile("slikaNaslovna");
        return await _pasService.InsertWithImage(request, cover);
    }

    [HttpPut("{ID:int}")]
    [Authorize(Roles = "Admin")]
    [Consumes("multipart/form-data")]
    public async Task<Model.Pas> Update(int ID, [FromForm] PasUpdateRequest request)
    {
        var cover = Request.Form.Files.GetFile("slikaNaslovna");
        return await _pasService.UpdateWithImage(ID, request, cover);
    }

    [HttpDelete("{ID:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<bool> Delete(int ID)
        => await _pasService.Delete(ID);

    [HttpPost("{pasId:int}/slike")]
    [Authorize(Roles = "Admin")]
    [Consumes("multipart/form-data")]
    public async Task<Model.SlikaPsa> AddSlika(int pasId, IFormFile slika, [FromForm] int redniBroj = 0)
        => await _pasService.AddSlika(pasId, slika, redniBroj);

    [HttpDelete("{pasId:int}/slike/{slikaId:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<bool> RemoveSlika(int pasId, int slikaId)
        => await _pasService.RemoveSlika(slikaId);
}
