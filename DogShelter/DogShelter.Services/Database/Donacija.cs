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

    public string? StripeRefundId { get; set; }

    public string? Napomena { get; set; }

    public int? ObradioKorisnikId { get; set; }

    public DateTime? DatumObrade { get; set; }

    public string? RazlogOdbijanja { get; set; }

    public string? RazlogVracanja { get; set; }

    public virtual Korisnik Korisnik { get; set; } = null!;

    public virtual Korisnik? ObradioKorisnik { get; set; }

    public virtual StatusDonacije StatusDonacije { get; set; } = null!;

    public virtual TipDonacije TipDonacije { get; set; } = null!;
}
