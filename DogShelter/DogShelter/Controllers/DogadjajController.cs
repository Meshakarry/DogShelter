using DogShelter.Model;
using DogShelter.Model.Requests;
using DogShelter.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace DogShelter.Controllers;

[Route("api/[controller]")]
[ApiController]
public class DogadjajController : ControllerBase
{
    private readonly IDogadjajService _service;

    public DogadjajController(IDogadjajService service)
    {
        _service = service;
    }

    [HttpGet]
    [Authorize]
    public async Task<PagedResult<Model.Dogadjaj>> Get([FromQuery] DogadjajSearchRequest search)
        => await _service.Get(search, User.IsInRole(RoleNames.Admin));

    [HttpGet("{ID:int}")]
    [Authorize]
    public async Task<Model.Dogadjaj> GetById(int ID)
        => await _service.GetById(ID, User.IsInRole(RoleNames.Admin));

    [HttpPost]
    [Authorize(Roles = RoleNames.Admin)]
    [Consumes("multipart/form-data")]
    public async Task<Model.Dogadjaj> Insert([FromForm] DogadjajInsertRequest request)
    {
        var slika = Request.Form.Files.GetFile("slika");
        return await _service.InsertWithImage(request, slika);
    }

    [HttpPut("{ID:int}")]
    [Authorize(Roles = RoleNames.Admin)]
    [Consumes("multipart/form-data")]
    public async Task<Model.Dogadjaj> Update(int ID, [FromForm] DogadjajUpdateRequest request)
    {
        var slika = Request.Form.Files.GetFile("slika");
        return await _service.UpdateWithImage(ID, request, slika);
    }

    [HttpDelete("{ID:int}")]
    [Authorize(Roles = RoleNames.Admin)]
    public async Task<bool> Delete(int ID)
        => await _service.Otkazi(ID);
}
