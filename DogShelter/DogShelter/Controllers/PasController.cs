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
    private readonly IPretragaLogService _pretragaLogService;

    public PasController(IPasService pasService, IPregledPsaService pregledService, IPretragaLogService pretragaLogService)
    {
        _pasService = pasService;
        _pregledService = pregledService;
        _pretragaLogService = pretragaLogService;
    }

    [HttpGet]
    [Authorize]
    public async Task<PagedResult<Model.PasListItem>> Get([FromQuery] PasSearchRequest search)
    {
        var isAdmin = User.IsInRole(RoleNames.Admin);
        var result = await _pasService.Get(search, isAdmin);

        var idClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (int.TryParse(idClaim, out var korisnikId))
        {
            try { await _pretragaLogService.LogPretragaAsync(search, korisnikId, isAdmin); }
            catch { /* log failure must never break a dog search */ }
        }

        return result;
    }

    [HttpGet("{ID:int}")]
    [Authorize]
    public async Task<Model.Pas> GetById(int ID)
    {
        var isAdmin = User.IsInRole(RoleNames.Admin);
        var pas = await _pasService.GetById(ID, isAdmin);

        var idClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!int.TryParse(idClaim, out var korisnikId))
            throw new ForbiddenException("Nije moguće identificirati korisnika.");

        // Admin browsing (desktop Psi) is not a recommender signal - same exclusion as
        // PretragaLogService already applies to admin searches. Only end-user views are logged.
        if (!isAdmin)
        {
            try { await _pregledService.LogPregled(ID, korisnikId); }
            catch { /* log failure must never break a dog read */ }
        }

        return pas;
    }

    [HttpPost]
    [Authorize(Roles = RoleNames.Admin)]
    [Consumes("multipart/form-data")]
    public async Task<Model.Pas> Insert([FromForm] PasInsertRequest request)
    {
        var cover = Request.Form.Files.GetFile("slikaNaslovna");
        return await _pasService.InsertWithImage(request, cover);
    }

    [HttpPut("{ID:int}")]
    [Authorize(Roles = RoleNames.Admin)]
    [Consumes("multipart/form-data")]
    public async Task<Model.Pas> Update(int ID, [FromForm] PasUpdateRequest request)
    {
        var cover = Request.Form.Files.GetFile("slikaNaslovna");
        return await _pasService.UpdateWithImage(ID, request, cover);
    }

    [HttpDelete("{ID:int}")]
    [Authorize(Roles = RoleNames.Admin)]
    public async Task<bool> Delete(int ID)
        => await _pasService.Delete(ID);

    [HttpPost("{pasId:int}/slike")]
    [Authorize(Roles = RoleNames.Admin)]
    [Consumes("multipart/form-data")]
    public async Task<Model.SlikaPsa> AddSlika(int pasId, IFormFile slika, [FromForm] int redniBroj = 0)
        => await _pasService.AddSlika(pasId, slika, redniBroj);

    [HttpDelete("{pasId:int}/slike/{slikaId:int}")]
    [Authorize(Roles = RoleNames.Admin)]
    public async Task<bool> RemoveSlika(int pasId, int slikaId)
        => await _pasService.RemoveSlika(slikaId);
}
