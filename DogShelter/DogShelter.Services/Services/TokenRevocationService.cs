using DogShelter.Services.Database;
using DogShelter.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DogShelter.Services.Services;

public class TokenRevocationService : ITokenRevocationService
{
    private readonly DogShelterContext _context;

    public TokenRevocationService(DogShelterContext context)
    {
        _context = context;
    }

    public async Task RevokeAsync(string jti, int korisnikId, DateTime expiresUtc)
    {
        if (await _context.RevokedTokens.AnyAsync(t => t.Jti == jti))
            return;

        _context.RevokedTokens.Add(new RevokedToken
        {
            Jti = jti,
            KorisnikId = korisnikId,
            ExpiresUtc = expiresUtc
        });

        await _context.SaveChangesAsync();
    }

    public Task<bool> IsRevokedAsync(string jti)
    {
        return _context.RevokedTokens.AsNoTracking().AnyAsync(t => t.Jti == jti);
    }
}
