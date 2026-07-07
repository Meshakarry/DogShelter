namespace DogShelter.Services.Database;

public partial class StatusDonacije
{
    public int StatusDonacijeId { get; set; }

    public string Naziv { get; set; } = null!;

    public virtual ICollection<Donacija> Donacijas { get; set; } = new List<Donacija>();
}
