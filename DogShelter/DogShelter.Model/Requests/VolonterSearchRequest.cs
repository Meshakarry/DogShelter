namespace DogShelter.Model.Requests;

public class VolonterSearchRequest : PagedSearchRequest
{
    public bool? Aktivan { get; set; }
    public string? Ime { get; set; }
}
