namespace DogShelter.Services.Database;

public partial class PregledPsa
{
    public int PregledPsaId { get; set; }

    public int KorisnikId { get; set; }

    public int PasId { get; set; }

    public DateTime DatumPregleda { get; set; }

    public virtual Korisnik Korisnik { get; set; } = null!;

    public virtual Pas Pas { get; set; } = null!;
}
