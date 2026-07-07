namespace DogShelter.Services.Database;

public partial class VelicinaPsa
{
    public int VelicinaPsaId { get; set; }

    public string Naziv { get; set; } = null!;

    public virtual ICollection<Pas> Pas { get; set; } = new List<Pas>();
}
