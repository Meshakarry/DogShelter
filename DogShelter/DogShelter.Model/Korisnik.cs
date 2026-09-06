using System.Text.Json.Serialization;

namespace DogShelter.Model;

// This type is returned as-is by /api/Korisnik/Token, /Register, /profile, GET /{id} and the
// admin list - it IS the public user response shape. The DB entity (Services/Database/Korisnik)
// carries LozinkaHash, LozinkaSalt and SigurnosniPecat; none of those may ever be added here as
// a serializable property. SigurnosniPecat is mirrored below only for the JWT generator and is
// [JsonIgnore]d - keep any future auth/secret field the same way, or off this class entirely.
public class Korisnik
{
    public int KorisnikId { get; set; }
    public string Ime { get; set; } = null!;
    public string Prezime { get; set; } = null!;
    public string Email { get; set; } = null!;
    public string? Telefon { get; set; }
    public int? GradId { get; set; }
    public string? Adresa { get; set; }
    public string KorisnickoIme { get; set; } = null!;
    public bool Aktivan { get; set; }
    public string? SlikaPutanja { get; set; }
    public DateTime DatumRegistracije { get; set; }
    public ICollection<KorisnikUloga> KorisnikUloge { get; set; } = null!;

    // Server-internal only (JwtTokenGenerator embeds it in the "sst" claim) - never serialized
    // into an API response.
    [JsonIgnore]
    public Guid SigurnosniPecat { get; set; }
}
