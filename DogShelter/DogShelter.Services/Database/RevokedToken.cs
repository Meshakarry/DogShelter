namespace DogShelter.Services.Database;

public partial class RevokedToken
{
    public int RevokedTokenId { get; set; }

    public int KorisnikId { get; set; }

    public string Jti { get; set; } = null!;

    public DateTime RevokedAt { get; set; }

    public DateTime ExpiresUtc { get; set; }

    public virtual Korisnik Korisnik { get; set; } = null!;
}
