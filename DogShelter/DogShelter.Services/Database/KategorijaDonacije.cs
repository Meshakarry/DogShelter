namespace DogShelter.Services.Database;

public partial class KategorijaDonacije
{
    public int KategorijaDonacijeId { get; set; }

    public string Naziv { get; set; } = null!;

    public string IkonaKljuc { get; set; } = null!;

    public virtual ICollection<Donacija> Donacijas { get; set; } = new List<Donacija>();
}
