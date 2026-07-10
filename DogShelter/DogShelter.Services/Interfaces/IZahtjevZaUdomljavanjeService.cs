using DogShelter.Model;
using DogShelter.Model.Requests;

namespace DogShelter.Services.Interfaces;

public interface IZahtjevZaUdomljavanjeService
{
    Task<PagedResult<ZahtjevZaUdomljavanje>> Get(ZahtjevZaUdomljavanjeSearchRequest search, int currentKorisnikId, bool isAdmin);
    Task<ZahtjevZaUdomljavanje> GetById(int id);
    Task<ZahtjevZaUdomljavanje> Insert(ZahtjevZaUdomljavanjeInsertRequest request, int korisnikId);
    Task<ZahtjevZaUdomljavanje> Odobri(int id, int adminKorisnikId);
    Task<ZahtjevZaUdomljavanje> Odbij(int id, ZahtjevZaUdomljavanjeOdbijRequest request, int adminKorisnikId);
}
