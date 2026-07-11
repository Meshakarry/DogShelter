namespace DogShelter.Model.Requests;

public class PosjetaSearchRequest : PagedSearchRequest
{
    public int? KorisnikId { get; set; }
    public int? PasId { get; set; }
    public int? StatusPosjeteId { get; set; }
    public DateTime? DatumOd { get; set; }
    public DateTime? DatumDo { get; set; }
}
