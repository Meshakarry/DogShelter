namespace DogShelter.Model;

public class Dogadjaj
{
    public int DogadjajId { get; set; }
    public string Naziv { get; set; } = null!;
    public string? Opis { get; set; }
    public DateTime Datum { get; set; }
    public string Lokacija { get; set; } = null!;
    public string? SlikaPutanja { get; set; }
    public bool Aktivan { get; set; }
    public int BrojZaduzenihVolontera { get; set; }
}
