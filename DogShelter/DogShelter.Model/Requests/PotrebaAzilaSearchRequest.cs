namespace DogShelter.Model.Requests;

public class PotrebaAzilaSearchRequest : PagedSearchRequest
{
    public string? Naziv { get; set; }
    public int? PrioritetPotrebeId { get; set; }
    public bool? Aktivna { get; set; }
}
