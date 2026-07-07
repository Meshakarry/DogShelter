namespace DogShelter.Model;

public class Pas
{
    public int PasId { get; set; }
    public string Naziv { get; set; } = null!;
    public int RasaId { get; set; }
    public bool Spol { get; set; }
    public DateOnly? DatumRodjenja { get; set; }
    public string? Opis { get; set; }
    public int StatusPsaId { get; set; }
    public int VelicinaPsaId { get; set; }
    public decimal? Tezina { get; set; }
    public DateOnly DatumPrijema { get; set; }
    public string? SlikaNaslovna { get; set; }
    public bool Vakcinisan { get; set; }
    public bool Sterilizovan { get; set; }
    public bool Aktivan { get; set; }
}
