namespace DogShelter.Services.Database;

public partial class ZahtjevZaUdomljavanje
{
    public int ZahtjevZaUdomljavanjeId { get; set; }

    public int KorisnikId { get; set; }

    public int PasId { get; set; }

    public int StatusZahtjevaId { get; set; }

    public DateTime DatumPodnosenja { get; set; }

    public string? Napomena { get; set; }

    public DateTime? DatumObrade { get; set; }

    public int? ObradioKorisnikId { get; set; }

    public string? RazlogOdbijanja { get; set; }

    public virtual Korisnik Korisnik { get; set; } = null!;

    public virtual Korisnik? ObradioKorisnik { get; set; }

    public virtual Pas Pas { get; set; } = null!;

    public virtual StatusZahtjeva StatusZahtjeva { get; set; } = null!;

    public virtual Udomljavanje? Udomljavanje { get; set; }
}
