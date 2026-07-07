namespace DogShelter.Services.Database;

public partial class DogadjajVolonter
{
    public int DogadjajVolonterId { get; set; }

    public int DogadjajId { get; set; }

    public int VolonterId { get; set; }

    public virtual Dogadjaj Dogadjaj { get; set; } = null!;

    public virtual Volonter Volonter { get; set; } = null!;
}
