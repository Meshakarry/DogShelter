using System.ComponentModel.DataAnnotations;

namespace DogShelter.Model.Requests;

public class DonacijaInsertRequest
{
    [Required(ErrorMessage = ValidationMessages.TipDonacijeIdRequired)]
    public int TipDonacijeId { get; set; }

    [Range(0.01, 1000000, ErrorMessage = ValidationMessages.IznosRange)]
    public decimal? Iznos { get; set; }

    [MaxLength(1000, ErrorMessage = ValidationMessages.NapomenaMaxLength)]
    public string? Napomena { get; set; }

    // --- Materijalna donacija details (only relevant/validated when TipDonacije == Materijalna) ---
    public int? KategorijaDonacijeId { get; set; }

    [MaxLength(200, ErrorMessage = ValidationMessages.PrilagodjenNazivMaxLength)]
    public string? PrilagodjenNaziv { get; set; }

    [Range(0.01, 100000, ErrorMessage = ValidationMessages.KolicinaRange)]
    public decimal? Kolicina { get; set; }

    public int? JedinicaMjereId { get; set; }

    public bool TrebaPreuzimanje { get; set; }

    [MaxLength(255, ErrorMessage = ValidationMessages.AdresaPreuzimanjaMaxLength)]
    public string? AdresaPreuzimanja { get; set; }

    [MaxLength(30, ErrorMessage = ValidationMessages.TelefonPreuzimanjaMaxLength)]
    public string? TelefonPreuzimanja { get; set; }

    public DateTime? DatumPreuzimanja { get; set; }

    public DateTime? ZeljeniDatumDostave { get; set; }
}
