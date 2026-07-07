namespace DogShelter.Services.Database;

public partial class SlikaPsa
{
    public int SlikaPsaId { get; set; }

    public int PasId { get; set; }

    public string Putanja { get; set; } = null!;

    public int RedniBroj { get; set; }

    public virtual Pas Pas { get; set; } = null!;
}
