namespace DogShelter.Model;

public class Udomljavanje
{
    public int UdomljavanjeId { get; set; }
    public int ZahtjevZaUdomljavanjeId { get; set; }
    public DateOnly DatumUdomljavanja { get; set; }
    public string? Napomena { get; set; }
}
