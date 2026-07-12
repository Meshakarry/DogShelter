using System.ComponentModel.DataAnnotations;

namespace DogShelter.Model.Requests;

public class DonacijaOdbijRequest
{
    [Required(ErrorMessage = ValidationMessages.RazlogOdbijanjaRequired)]
    [MaxLength(1000, ErrorMessage = ValidationMessages.RazlogOdbijanjaMaxLength)]
    public string RazlogOdbijanja { get; set; } = null!;
}
