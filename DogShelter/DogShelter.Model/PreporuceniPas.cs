namespace DogShelter.Model;

public class PreporuceniPas
{
    public int PasId { get; set; }
    public string Naziv { get; set; } = null!;
    public string RasaNaziv { get; set; } = null!;
    public string VelicinaNaziv { get; set; } = null!;
    public string SlikaNaslovna { get; set; } = null!;
    public DateOnly? DatumRodjenja { get; set; }
    public double Skor { get; set; }
    public string Razlog { get; set; } = null!;
    public bool Personalizovano { get; set; }
}
