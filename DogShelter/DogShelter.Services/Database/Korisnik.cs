namespace DogShelter.Services.Database;

public partial class Korisnik
{
    public int KorisnikId { get; set; }

    public string Ime { get; set; } = null!;

    public string Prezime { get; set; } = null!;

    public string Email { get; set; } = null!;

    public string LozinkaHash { get; set; } = null!;

    public string LozinkaSalt { get; set; } = null!;

    public string? Telefon { get; set; }

    public int? GradId { get; set; }

    public string? Adresa { get; set; }

    public string KorisnickoIme { get; set; } = null!;

    public bool Aktivan { get; set; }

    public string? SlikaPutanja { get; set; }

    // Bumped on any security-sensitive change (password change, role change, deactivation) so
    // JWTs issued before that change stop validating even though they haven't expired yet - see
    // Program.cs OnTokenValidated. Not client-readable/writable through any request DTO.
    public Guid SigurnosniPecat { get; set; } = Guid.NewGuid();

    public DateTime DatumRegistracije { get; set; }

    public virtual ICollection<Donacija> DonacijaKorisniks { get; set; } = new List<Donacija>();

    public virtual ICollection<Donacija> DonacijaObradioKorisniks { get; set; } = new List<Donacija>();

    public virtual Grad? Grad { get; set; }

    public virtual ICollection<KorisnikUloga> KorisnikUlogas { get; set; } = new List<KorisnikUloga>();

    public virtual ICollection<LozinkaResetToken> LozinkaResetTokens { get; set; } = new List<LozinkaResetToken>();

    public virtual ICollection<Notifikacija> Notifikacijas { get; set; } = new List<Notifikacija>();

    public virtual ICollection<Obavijest> Obavijests { get; set; } = new List<Obavijest>();

    public virtual ICollection<Posjeta> PosjetaKorisniks { get; set; } = new List<Posjeta>();

    public virtual ICollection<Posjeta> PosjetaObradioKorisniks { get; set; } = new List<Posjeta>();

    public virtual ICollection<PregledPsa> PregledPsas { get; set; } = new List<PregledPsa>();

    public virtual ICollection<Favorit> Favoriti { get; set; } = new List<Favorit>();

    public virtual ICollection<PretragaLog> PretragaLogs { get; set; } = new List<PretragaLog>();

    public virtual ICollection<RevokedToken> RevokedTokens { get; set; } = new List<RevokedToken>();

    public virtual Volonter? Volonter { get; set; }

    public virtual ICollection<ZahtjevZaUdomljavanje> ZahtjevZaUdomljavanjeKorisniks { get; set; } = new List<ZahtjevZaUdomljavanje>();

    public virtual ICollection<ZahtjevZaUdomljavanje> ZahtjevZaUdomljavanjeObradioKorisniks { get; set; } = new List<ZahtjevZaUdomljavanje>();
}
