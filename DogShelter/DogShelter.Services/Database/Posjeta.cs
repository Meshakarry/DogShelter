namespace DogShelter.Services.Database;

public partial class Posjeta
{
    public int PosjetaId { get; set; }

    public int KorisnikId { get; set; }

    public DateTime DatumVrijeme { get; set; }

    public int StatusPosjeteId { get; set; }

    public string? Napomena { get; set; }

    public virtual Korisnik Korisnik { get; set; } = null!;

    public virtual StatusPosjete StatusPosjete { get; set; } = null!;
}
