using DogShelter.Model;
using DogShelter.Model.Requests;

namespace DogShelter.Services.Interfaces;

public interface IPregledPsaService
{
    Task<PagedResult<Model.PregledPsa>> Get(PregledPsaSearchRequest search);
    Task<Model.PregledPsa> LogPregled(int pasId, int korisnikId);
}
