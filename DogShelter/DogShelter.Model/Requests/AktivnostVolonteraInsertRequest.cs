using System.ComponentModel.DataAnnotations;

namespace DogShelter.Model.Requests;

public class AktivnostVolonteraInsertRequest
{
    /// <summary>Only honored when the caller is Admin; a Volonter caller is always scoped to their own record.</summary>
    public int? VolonterId { get; set; }

    [Required(ErrorMessage = ValidationMessages.TipAktivnostiIdRequired)]
    public int TipAktivnostiId { get; set; }

    [Required(ErrorMessage = ValidationMessages.DatumAktivnostiRequired)]
    public DateOnly DatumAktivnosti { get; set; }

    [Range(0.1, 24, ErrorMessage = ValidationMessages.BrojSatiRange)]
    public decimal BrojSati { get; set; }

    [MaxLength(1000, ErrorMessage = ValidationMessages.AktivnostOpisMaxLength)]
    public string? Opis { get; set; }
}
