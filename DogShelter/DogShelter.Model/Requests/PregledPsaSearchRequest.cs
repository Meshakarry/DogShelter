namespace DogShelter.Model.Requests;

public class PregledPsaSearchRequest : PagedSearchRequest
{
    public int? KorisnikId { get; set; }
    public int? PasId { get; set; }
    public DateTime? OdDatuma { get; set; }
    public DateTime? DoDatuma { get; set; }
}
