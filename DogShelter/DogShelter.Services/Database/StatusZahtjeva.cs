namespace DogShelter.Services.Database;

public partial class StatusZahtjeva
{
    public int StatusZahtjevaId { get; set; }

    public string Naziv { get; set; } = null!;

    public virtual ICollection<ZahtjevZaUdomljavanje> ZahtjevZaUdomljavanjes { get; set; } = new List<ZahtjevZaUdomljavanje>();
}
