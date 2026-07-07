namespace DogShelter.Model.Requests
{
    public class LookupSearchRequest : PagedSearchRequest
    {
        public string? Naziv { get; set; }
    }
}
