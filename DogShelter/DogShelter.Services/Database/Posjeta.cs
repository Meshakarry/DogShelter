namespace DogShelter.Services.Database;

public partial class Posjeta
{
    public int PosjetaId { get; set; }

    public int KorisnikId { get; set; }

    public int? PasId { get; set; }

    public DateTime DatumVrijeme { get; set; }

    public int StatusPosjeteId { get; set; }

    public string? Napomena { get; set; }

    public DateTime DatumKreiranja { get; set; }

    public DateTime? DatumObrade { get; set; }

    public int? ObradioKorisnikId { get; set; }

    public string? RazlogOtkazivanja { get; set; }

    public virtual Korisnik Korisnik { get; set; } = null!;

    public virtual Korisnik? ObradioKorisnik { get; set; }

    public virtual Pas? Pas { get; set; }

    public virtual StatusPosjete StatusPosjete { get; set; } = null!;
}
