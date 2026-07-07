namespace DogShelter.Model.Requests
{
    public class RasaSearchRequest : PagedSearchRequest
    {
        public string? Naziv { get; set; }
        public bool? Aktivan { get; set; }
    }
}
