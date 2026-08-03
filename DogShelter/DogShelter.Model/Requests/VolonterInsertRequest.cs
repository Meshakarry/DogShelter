using System.ComponentModel.DataAnnotations;

namespace DogShelter.Model.Requests;

public class VolonterInsertRequest
{
    [Required(ErrorMessage = ValidationMessages.KorisnikIdRequired)]
    public int KorisnikId { get; set; }

    [Required(ErrorMessage = ValidationMessages.DatumPridruzivanjaRequired)]
    public DateOnly DatumPridruzivanja { get; set; }

    [MaxLength(500, ErrorMessage = ValidationMessages.VolonterNapomenaMaxLength)]
    public string? Napomena { get; set; }
}
