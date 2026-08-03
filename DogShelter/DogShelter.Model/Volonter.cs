namespace DogShelter.Model;

public class Volonter
{
    public int VolonterId { get; set; }
    public int KorisnikId { get; set; }
    public string? KorisnikIme { get; set; }
    public string? KorisnikPrezime { get; set; }
    public string? KorisnikEmail { get; set; }
    public string? KorisnikTelefon { get; set; }
    public DateOnly DatumPridruzivanja { get; set; }
    public bool Aktivan { get; set; }
    public string? Napomena { get; set; }
    public decimal UkupnoSati { get; set; }
}
