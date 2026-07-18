namespace DogShelter.Model.Requests;

public class AktivnostVolonteraSearchRequest : PagedSearchRequest
{
    public int? VolonterId { get; set; }
    public int? TipAktivnostiId { get; set; }
    public DateOnly? DatumOd { get; set; }
    public DateOnly? DatumDo { get; set; }
}
