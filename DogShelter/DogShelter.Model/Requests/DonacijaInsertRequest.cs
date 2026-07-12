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
}
