namespace DogShelter.Model;

public class Notifikacija
{
    public int NotifikacijaId { get; set; }
    public string Tip { get; set; } = null!;
    public string Naslov { get; set; } = null!;
    public string Tekst { get; set; } = null!;
    public int? VezaniEntitetId { get; set; }
    public bool Procitano { get; set; }
    public DateTime DatumKreiranja { get; set; }
}
