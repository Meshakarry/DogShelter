namespace DogShelter.Services.Database;

public partial class Favorit
{
    public int FavoritId { get; set; }

    public int KorisnikId { get; set; }

    public int PasId { get; set; }

    public DateTime DatumDodavanja { get; set; }

    public virtual Korisnik Korisnik { get; set; } = null!;

    public virtual Pas Pas { get; set; } = null!;
}
