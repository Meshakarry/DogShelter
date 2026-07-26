using DogShelter.Model;
using DogShelter.Model.Requests;

namespace DogShelter.Services.Interfaces;

public interface IPosjetaService
{
    Task<PagedResult<Posjeta>> Get(PosjetaSearchRequest search, int currentKorisnikId, bool isAdmin);
    Task<Posjeta> GetById(int id);
    Task<Posjeta> Insert(PosjetaInsertRequest request, int korisnikId);
    Task<Posjeta> InsertAdmin(PosjetaAdminInsertRequest request, int adminKorisnikId);
    Task<Posjeta> Potvrdi(int id, int adminKorisnikId);
    Task<Posjeta> Otkazi(int id, PosjetaOtkaziRequest request, int callerKorisnikId, bool isAdmin);
    Task<Posjeta> Zavrsi(int id, int adminKorisnikId);
    Task<List<DateTime>> GetZauzetiTermini(DateTime datum);
}
