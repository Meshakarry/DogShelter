using System.ComponentModel.DataAnnotations;

namespace DogShelter.Model.Requests;

public class DonacijaRefundRequest
{
    [Required(ErrorMessage = ValidationMessages.RazlogVracanjaRequired)]
    [MaxLength(1000, ErrorMessage = ValidationMessages.RazlogVracanjaMaxLength)]
    public string RazlogVracanja { get; set; } = null!;
}
