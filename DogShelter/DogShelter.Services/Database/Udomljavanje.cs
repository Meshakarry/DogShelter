namespace DogShelter.Services.Database;

public partial class Udomljavanje
{
    public int UdomljavanjeId { get; set; }

    public int ZahtjevZaUdomljavanjeId { get; set; }

    public DateOnly DatumUdomljavanja { get; set; }

    public string? Napomena { get; set; }

    public virtual ZahtjevZaUdomljavanje ZahtjevZaUdomljavanje { get; set; } = null!;
}
