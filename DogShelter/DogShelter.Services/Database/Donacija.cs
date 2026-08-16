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

    // --- Materijalna donacija details (all null for Novčana) ---
    public int? KategorijaDonacijeId { get; set; }

    public string? PrilagodjenNaziv { get; set; }

    public decimal? Kolicina { get; set; }

    public int? JedinicaMjereId { get; set; }

    public bool TrebaPreuzimanje { get; set; }

    public string? AdresaPreuzimanja { get; set; }

    public string? TelefonPreuzimanja { get; set; }

    public DateTime? DatumPreuzimanja { get; set; }

    public DateTime? ZeljeniDatumDostave { get; set; }

    // Guards against two near-simultaneous Stripe webhook deliveries for the same event both
    // reading "Na čekanju" before either commits — see HandlePaymentSucceededAsync/HandlePaymentFailedAsync.
    public byte[] RowVersion { get; set; } = null!;

    public virtual Korisnik Korisnik { get; set; } = null!;

    public virtual Korisnik? ObradioKorisnik { get; set; }

    public virtual StatusDonacije StatusDonacije { get; set; } = null!;

    public virtual TipDonacije TipDonacije { get; set; } = null!;

    public virtual KategorijaDonacije? KategorijaDonacije { get; set; }

    public virtual JedinicaMjere? JedinicaMjere { get; set; }
}
