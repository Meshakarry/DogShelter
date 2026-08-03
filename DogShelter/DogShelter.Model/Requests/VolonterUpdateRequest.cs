using System.ComponentModel.DataAnnotations;

namespace DogShelter.Model.Requests;

public class VolonterUpdateRequest
{
    public bool Aktivan { get; set; }

    [MaxLength(500, ErrorMessage = ValidationMessages.VolonterNapomenaMaxLength)]
    public string? Napomena { get; set; }
}
