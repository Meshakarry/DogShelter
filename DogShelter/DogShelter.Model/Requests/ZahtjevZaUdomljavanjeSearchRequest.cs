namespace DogShelter.Model.Requests;

public class ZahtjevZaUdomljavanjeSearchRequest : PagedSearchRequest
{
    public int? KorisnikId { get; set; }
    public int? PasId { get; set; }
    public int? StatusZahtjevaId { get; set; }
}
