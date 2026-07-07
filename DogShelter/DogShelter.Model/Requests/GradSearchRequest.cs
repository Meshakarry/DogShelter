namespace DogShelter.Model.Requests
{
    public class GradSearchRequest : PagedSearchRequest
    {
        public string? Naziv { get; set; }
        public string? PostanskiBroj { get; set; }
    }
}
