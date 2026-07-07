namespace DogShelter.Services.Database;

public partial class StatusPosjete
{
    public int StatusPosjeteId { get; set; }

    public string Naziv { get; set; } = null!;

    public virtual ICollection<Posjeta> Posjeta { get; set; } = new List<Posjeta>();
}
