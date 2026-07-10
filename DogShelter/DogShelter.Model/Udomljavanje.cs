namespace DogShelter.Model;

public class Udomljavanje
{
    public int UdomljavanjeId { get; set; }
    public int ZahtjevZaUdomljavanjeId { get; set; }
    public DateOnly DatumUdomljavanja { get; set; }
    public string? Napomena { get; set; }
    public int PasId { get; set; }
    public string? PasNaziv { get; set; }
    public string? PasSlikaNaslovna { get; set; }
    public int KorisnikId { get; set; }
    public string? KorisnikIme { get; set; }
    public string? KorisnikPrezime { get; set; }
}
