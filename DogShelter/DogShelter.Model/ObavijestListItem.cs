namespace DogShelter.Model;

public class ObavijestListItem
{
    public int ObavijestId { get; set; }
    public string Naslov { get; set; } = null!;
    public string? SlikaPutanja { get; set; }
    public DateTime DatumObjave { get; set; }
    public int AutorId { get; set; }
    public string? AutorIme { get; set; }
    public string? AutorPrezime { get; set; }
    public bool Aktivna { get; set; }
}
