namespace DogShelter.Services.Interfaces;

public interface IFavoritService
{
    Task<List<Model.Favorit>> GetMineAsync(int korisnikId);
    Task<Model.Favorit> AddAsync(int korisnikId, int pasId);
    Task RemoveAsync(int korisnikId, int pasId);
}
