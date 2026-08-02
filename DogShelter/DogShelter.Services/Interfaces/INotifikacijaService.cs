using DogShelter.Model;
using DogShelter.Model.Requests;

namespace DogShelter.Services.Interfaces;

public interface INotifikacijaService
{
    void StageCreate(int korisnikId, string tip, string naslov, string tekst, int? vezaniEntitetId = null);
    Task CreateAsync(int korisnikId, string tip, string naslov, string tekst, int? vezaniEntitetId = null);
    Task StageCreateForRoleAsync(string uloga, string tip, string naslov, string tekst, int? vezaniEntitetId = null);
    Task<PagedResult<Model.Notifikacija>> Get(NotifikacijaSearchRequest search, int korisnikId);
    Task<int> GetUnreadCount(int korisnikId);
    Task<bool> OznaciProcitano(int korisnikId, int notifikacijaId);
    Task OznaciSveProcitano(int korisnikId);
}
