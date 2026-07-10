using System.ComponentModel.DataAnnotations;

namespace DogShelter.Model.Requests;

public class ZahtjevZaUdomljavanjeInsertRequest
{
    [Required(ErrorMessage = ValidationMessages.PasIdRequired)]
    public int PasId { get; set; }

    [MaxLength(1000, ErrorMessage = ValidationMessages.NapomenaMaxLength)]
    public string? Napomena { get; set; }
}
