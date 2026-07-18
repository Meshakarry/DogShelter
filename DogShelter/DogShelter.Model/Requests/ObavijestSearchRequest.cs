namespace DogShelter.Model.Requests;

public class ObavijestSearchRequest : PagedSearchRequest
{
    public string? Naslov { get; set; }
    public bool? Aktivna { get; set; }
    public int? AutorId { get; set; }
    public DateTime? DatumOd { get; set; }
    public DateTime? DatumDo { get; set; }
}
