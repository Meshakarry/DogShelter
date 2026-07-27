namespace DogShelter.Services.Database;

public partial class JedinicaMjere
{
    public int JedinicaMjereId { get; set; }

    public string Naziv { get; set; } = null!;

    public virtual ICollection<Donacija> Donacijas { get; set; } = new List<Donacija>();
}
