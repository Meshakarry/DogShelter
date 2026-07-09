namespace DogShelter.Model.Requests;

public class PasSearchRequest : PagedSearchRequest
{
    public string? Naziv { get; set; }
    public int? RasaId { get; set; }
    public int? StatusPsaId { get; set; }
    public int? VelicinaPsaId { get; set; }
    public Spol? Spol { get; set; }
    public bool? Aktivan { get; set; }
    public bool? Vakcinisan { get; set; }
    public bool? Sterilizovan { get; set; }
}
