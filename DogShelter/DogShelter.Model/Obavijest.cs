namespace DogShelter.Model;

public class Obavijest
{
    public int ObavijestId { get; set; }
    public string Naslov { get; set; } = null!;
    public string Sadrzaj { get; set; } = null!;
    public string? SlikaPutanja { get; set; }
    public DateTime DatumObjave { get; set; }
    public int AutorId { get; set; }
    public bool Aktivna { get; set; }
}
