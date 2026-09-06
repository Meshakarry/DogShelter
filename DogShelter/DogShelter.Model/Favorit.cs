namespace DogShelter.Model;

public class Favorit
{
    public int FavoritId { get; set; }
    public int KorisnikId { get; set; }
    public int PasId { get; set; }
    public DateTime DatumDodavanja { get; set; }

    // Denormalized dog display fields so "Moji favoriti" can render a card straight off this
    // list, the same way PreporuceniPas carries what it needs instead of a second round-trip.
    public string PasNaziv { get; set; } = null!;
    public string? RasaNaziv { get; set; }
    public string? VelicinaNaziv { get; set; }
    public string SlikaNaslovna { get; set; } = null!;
    public string? StatusNaziv { get; set; }
    public bool PasAktivan { get; set; }
}
