namespace DogShelter.Model;

public class Volonter
{
    public int VolonterId { get; set; }
    public int KorisnikId { get; set; }
    public DateOnly DatumPridruzivanja { get; set; }
    public bool Aktivan { get; set; }
}
