namespace DogShelter.Model;

public class ZahtjevZaUdomljavanje
{
    public int ZahtjevZaUdomljavanjeId { get; set; }
    public int KorisnikId { get; set; }
    public int PasId { get; set; }
    public int StatusZahtjevaId { get; set; }
    public DateTime DatumPodnosenja { get; set; }
    public string? Napomena { get; set; }
    public DateTime? DatumObrade { get; set; }
    public int? ObradioKorisnikId { get; set; }
    public string? RazlogOdbijanja { get; set; }
}
