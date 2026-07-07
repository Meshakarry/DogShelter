namespace DogShelter.Services.Database;

public partial class TipDonacije
{
    public int TipDonacijeId { get; set; }

    public string Naziv { get; set; } = null!;

    public virtual ICollection<Donacija> Donacijas { get; set; } = new List<Donacija>();
}
