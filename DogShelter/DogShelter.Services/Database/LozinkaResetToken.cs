namespace DogShelter.Services.Database;

public partial class LozinkaResetToken
{
    public int LozinkaResetTokenId { get; set; }

    public int KorisnikId { get; set; }

    public string KodHash { get; set; } = null!;

    public DateTime DatumKreiranja { get; set; }

    public DateTime IsticeU { get; set; }

    public bool Iskoristen { get; set; }

    public virtual Korisnik Korisnik { get; set; } = null!;
}
