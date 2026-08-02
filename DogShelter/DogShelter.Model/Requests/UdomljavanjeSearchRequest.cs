namespace DogShelter.Model.Requests;

public class UdomljavanjeSearchRequest : PagedSearchRequest
{
    public int? KorisnikId { get; set; }
    public int? PasId { get; set; }
    public DateTime? DatumOd { get; set; }
    public DateTime? DatumDo { get; set; }
}
