namespace DogShelter.Model.Requests;

public class NotifikacijaSearchRequest : PagedSearchRequest
{
    public bool? Procitano { get; set; }
}
