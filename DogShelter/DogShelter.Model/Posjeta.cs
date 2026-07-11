namespace DogShelter.Model;

public class Posjeta
{
    public int PosjetaId { get; set; }
    public int KorisnikId { get; set; }
    public string? KorisnikIme { get; set; }
    public string? KorisnikPrezime { get; set; }
    public int? PasId { get; set; }
    public string? PasNaziv { get; set; }
    public string? PasSlikaNaslovna { get; set; }
    public DateTime DatumVrijeme { get; set; }
    public int StatusPosjeteId { get; set; }
    public string? StatusPosjeteNaziv { get; set; }
    public string? Napomena { get; set; }
    public DateTime DatumKreiranja { get; set; }
    public DateTime? DatumObrade { get; set; }
    public int? ObradioKorisnikId { get; set; }
    public string? ObradioKorisnikIme { get; set; }
    public string? ObradioKorisnikPrezime { get; set; }
    public string? RazlogOtkazivanja { get; set; }
}
