namespace DogShelter.Services.Database;

public partial class Rasa
{
    public int RasaId { get; set; }

    public string Naziv { get; set; } = null!;

    public bool Aktivan { get; set; }

    public virtual ICollection<Pas> Pas { get; set; } = new List<Pas>();
}
