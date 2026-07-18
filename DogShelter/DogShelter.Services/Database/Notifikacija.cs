namespace DogShelter.Services.Database;

public partial class Notifikacija
{
    public int NotifikacijaId { get; set; }

    public int KorisnikId { get; set; }

    public string Tip { get; set; } = null!;

    public string Naslov { get; set; } = null!;

    public string Tekst { get; set; } = null!;

    public int? VezaniEntitetId { get; set; }

    public bool Procitano { get; set; }

    public DateTime DatumKreiranja { get; set; }

    public virtual Korisnik Korisnik { get; set; } = null!;
}
