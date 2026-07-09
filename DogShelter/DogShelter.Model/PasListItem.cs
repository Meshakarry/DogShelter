namespace DogShelter.Model;

public class PasListItem
{
    public int PasId { get; set; }
    public string Naziv { get; set; } = null!;
    public int RasaId { get; set; }
    public string? RasaNaziv { get; set; }
    public Spol Spol { get; set; }
    public DateOnly? DatumRodjenja { get; set; }
    public int StatusPsaId { get; set; }
    public string? StatusNaziv { get; set; }
    public int VelicinaPsaId { get; set; }
    public string? VelicinaNaziv { get; set; }
    public decimal? Tezina { get; set; }
    public DateOnly DatumPrijema { get; set; }
    public string? SlikaNaslovna { get; set; }
    public bool Vakcinisan { get; set; }
    public bool Sterilizovan { get; set; }
    public bool Aktivan { get; set; }
}
