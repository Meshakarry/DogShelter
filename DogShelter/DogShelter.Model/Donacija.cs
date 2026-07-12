namespace DogShelter.Model;

public class Donacija
{
    public int DonacijaId { get; set; }
    public int KorisnikId { get; set; }
    public string? KorisnikIme { get; set; }
    public string? KorisnikPrezime { get; set; }
    public int TipDonacijeId { get; set; }
    public string? TipDonacijeNaziv { get; set; }
    public int StatusDonacijeId { get; set; }
    public string? StatusDonacijeNaziv { get; set; }
    public decimal? Iznos { get; set; }
    public DateTime DatumDonacije { get; set; }
    public string? Napomena { get; set; }
    public int? ObradioKorisnikId { get; set; }
    public string? ObradioKorisnikIme { get; set; }
    public string? ObradioKorisnikPrezime { get; set; }
    public DateTime? DatumObrade { get; set; }
    public string? RazlogOdbijanja { get; set; }
    public string? RazlogVracanja { get; set; }
    public bool IsPaid { get; set; }
}
