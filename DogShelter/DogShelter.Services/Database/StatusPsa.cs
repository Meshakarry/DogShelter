namespace DogShelter.Services.Database;

public partial class StatusPsa
{
    public int StatusPsaId { get; set; }

    public string Naziv { get; set; } = null!;

    public virtual ICollection<Pas> Pas { get; set; } = new List<Pas>();
}
