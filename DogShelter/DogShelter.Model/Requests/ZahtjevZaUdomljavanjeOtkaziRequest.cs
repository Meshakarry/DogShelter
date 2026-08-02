using System.ComponentModel.DataAnnotations;

namespace DogShelter.Model.Requests;

public class ZahtjevZaUdomljavanjeOtkaziRequest
{
    [Required(ErrorMessage = ValidationMessages.RazlogOtkazivanjaRequired)]
    [MaxLength(1000, ErrorMessage = ValidationMessages.RazlogOtkazivanjaMaxLength)]
    public string RazlogOtkazivanja { get; set; } = null!;
}
