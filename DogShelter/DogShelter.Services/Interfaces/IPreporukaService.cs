namespace DogShelter.Services.Interfaces;

public interface IPreporukaService
{
    Task<List<Model.PreporuceniPas>> PreporuceniPsi(int korisnikId, int take);
}
