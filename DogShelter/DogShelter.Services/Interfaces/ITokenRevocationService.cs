namespace DogShelter.Services.Interfaces;

public interface ITokenRevocationService
{
    Task RevokeAsync(string jti, int korisnikId, DateTime expiresUtc);
    Task<bool> IsRevokedAsync(string jti);
}
