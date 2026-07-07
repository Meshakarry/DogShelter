namespace DogShelter.Services.Database;

public partial class Grad
{
    public int GradId { get; set; }

    public string Naziv { get; set; } = null!;

    public string PostanskiBroj { get; set; } = null!;

    public virtual ICollection<Korisnik> Korisniks { get; set; } = new List<Korisnik>();
}
