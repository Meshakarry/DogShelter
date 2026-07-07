namespace DogShelter.Services.Database;

public partial class Donacija
{
    public int DonacijaId { get; set; }

    public int KorisnikId { get; set; }

    public int TipDonacijeId { get; set; }

    public int StatusDonacijeId { get; set; }

    public decimal? Iznos { get; set; }

    public DateTime DatumDonacije { get; set; }

    public string? StripePaymentIntentId { get; set; }

    public string? Napomena { get; set; }

    public virtual Korisnik Korisnik { get; set; } = null!;

    public virtual StatusDonacije StatusDonacije { get; set; } = null!;

    public virtual TipDonacije TipDonacije { get; set; } = null!;
}
