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
    public List<DonacijaStavkaRequest> Stavke { get; set; } = new();

    public bool TrebaPreuzimanje { get; set; }

    [MaxLength(255, ErrorMessage = ValidationMessages.AdresaPreuzimanjaMaxLength)]
    public string? AdresaPreuzimanja { get; set; }

    [RegularExpression(ValidationPatterns.Phone, ErrorMessage = ValidationPatterns.PhoneErrorMessage)]
    public string? TelefonPreuzimanja { get; set; }

    public DateTime? DatumPreuzimanja { get; set; }

    public DateTime? ZeljeniDatumDostave { get; set; }
}
