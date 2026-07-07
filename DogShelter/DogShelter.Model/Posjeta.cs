namespace DogShelter.Model;

public class Posjeta
{
    public int PosjetaId { get; set; }
    public int KorisnikId { get; set; }
    public DateTime DatumVrijeme { get; set; }
    public int StatusPosjeteId { get; set; }
    public string? Napomena { get; set; }
}
