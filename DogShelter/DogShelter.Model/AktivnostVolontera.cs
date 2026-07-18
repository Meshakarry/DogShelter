namespace DogShelter.Model;

public class AktivnostVolontera
{
    public int AktivnostVolonteraId { get; set; }
    public int VolonterId { get; set; }
    public int KorisnikId { get; set; }
    public string? VolonterIme { get; set; }
    public string? VolonterPrezime { get; set; }
    public int TipAktivnostiId { get; set; }
    public string? TipAktivnostiNaziv { get; set; }
    public DateOnly DatumAktivnosti { get; set; }
    public decimal BrojSati { get; set; }
    public string? Opis { get; set; }
}
