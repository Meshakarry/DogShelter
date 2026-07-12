namespace DogShelter.Model.Requests;

public class DonacijaSearchRequest : PagedSearchRequest
{
    public int? KorisnikId { get; set; }
    public int? TipDonacijeId { get; set; }
    public int? StatusDonacijeId { get; set; }
    public DateTime? DatumOd { get; set; }
    public DateTime? DatumDo { get; set; }
}
