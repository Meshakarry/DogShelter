using System.ComponentModel.DataAnnotations;

namespace DogShelter.Model.Requests;

public class DogadjajVolonterInsertRequest
{
    [Required(ErrorMessage = ValidationMessages.DogadjajIdRequired)]
    public int DogadjajId { get; set; }

    [Required(ErrorMessage = ValidationMessages.VolonterIdRequired)]
    public int VolonterId { get; set; }
}
