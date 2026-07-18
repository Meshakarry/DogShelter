namespace DogShelter.Model.Requests;

public class DogadjajSearchRequest : PagedSearchRequest
{
    public string? Naziv { get; set; }
    public bool? Aktivan { get; set; }
    public DateTime? DatumOd { get; set; }
    public DateTime? DatumDo { get; set; }
}
