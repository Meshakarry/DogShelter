namespace DogShelter.Model.Requests;

public class DogadjajVolonterSearchRequest : PagedSearchRequest
{
    public int? DogadjajId { get; set; }
    public int? VolonterId { get; set; }
}
