namespace DogShelter.Model;

public class ZahtjevZaUdomljavanje
{
    public int ZahtjevZaUdomljavanjeId { get; set; }
    public int KorisnikId { get; set; }
    public string? KorisnikIme { get; set; }
    public string? KorisnikPrezime { get; set; }
    public int PasId { get; set; }
    public string? PasNaziv { get; set; }
    public string? PasSlikaNaslovna { get; set; }

    // Lets the client disable "Odobri" (rather than let the click round-trip to Odobri()'s own
    // Aktivan/Dostupan re-check) when the dog stopped being adoptable after the request was
    // submitted - e.g. deactivated, or already reserved/adopted via a different request.
    public bool PasAktivan { get; set; }
    public string? PasStatusNaziv { get; set; }
    public int StatusZahtjevaId { get; set; }
    public string? StatusZahtjevaNaziv { get; set; }
    public DateTime DatumPodnosenja { get; set; }
    public string? Napomena { get; set; }
    public DateTime? DatumObrade { get; set; }
    public int? ObradioKorisnikId { get; set; }
    public string? ObradioKorisnikIme { get; set; }
    public string? ObradioKorisnikPrezime { get; set; }
    public string? RazlogOdbijanja { get; set; }

    // True once FinalizirajUdomljenje has actually run for this request (an Udomljavanje row
    // exists) - lets clients tell an Odobren-but-not-yet-finalized request (dog Rezervisan, action
    // still pending) apart from an Odobren request that was already finalized long ago (dog
    // Udomljen), since StatusZahtjevaNaziv stays "Odobren" forever in both cases.
    public bool UdomljenjeFinalizovano { get; set; }
}
