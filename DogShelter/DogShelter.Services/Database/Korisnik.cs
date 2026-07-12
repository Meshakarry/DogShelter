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

    public DateTime DatumRegistracije { get; set; }

    public virtual ICollection<Donacija> DonacijaKorisniks { get; set; } = new List<Donacija>();

    public virtual ICollection<Donacija> DonacijaObradioKorisniks { get; set; } = new List<Donacija>();

    public virtual Grad? Grad { get; set; }

    public virtual ICollection<KorisnikUloga> KorisnikUlogas { get; set; } = new List<KorisnikUloga>();

    public virtual ICollection<LozinkaResetToken> LozinkaResetTokens { get; set; } = new List<LozinkaResetToken>();

    public virtual ICollection<Obavijest> Obavijests { get; set; } = new List<Obavijest>();

    public virtual ICollection<Posjeta> PosjetaKorisniks { get; set; } = new List<Posjeta>();

    public virtual ICollection<Posjeta> PosjetaObradioKorisniks { get; set; } = new List<Posjeta>();

    public virtual ICollection<PregledPsa> PregledPsas { get; set; } = new List<PregledPsa>();

    public virtual Volonter? Volonter { get; set; }

    public virtual ICollection<ZahtjevZaUdomljavanje> ZahtjevZaUdomljavanjeKorisniks { get; set; } = new List<ZahtjevZaUdomljavanje>();

    public virtual ICollection<ZahtjevZaUdomljavanje> ZahtjevZaUdomljavanjeObradioKorisniks { get; set; } = new List<ZahtjevZaUdomljavanje>();
}
