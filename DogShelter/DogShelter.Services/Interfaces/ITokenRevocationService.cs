namespace DogShelter.Services.Interfaces;

public interface ITokenRevocationService
{
    Task RevokeAsync(string jti, int korisnikId, DateTime expiresUtc);
    Task<bool> IsRevokedAsync(string jti);

    // Rejects a token whose "sst" claim no longer matches the user's current SigurnosniPecat
    // (bumped on password change/role change/deactivation - see KorisnikService) or whose user
    // is no longer active. Unlike RevokeAsync/IsRevokedAsync, which opt out one specific token by
    // jti, this invalidates every token issued before the security-relevant change, without the
    // API needing to know which tokens exist.
    Task<bool> IsSecurityStampValidAsync(int korisnikId, Guid tokenStamp);
}
