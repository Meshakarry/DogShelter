using System.ComponentModel.DataAnnotations;

namespace DogShelter.Model.Requests;

public class FavoritInsertRequest
{
    [Required(ErrorMessage = ValidationMessages.PasIdRequired)]
    public int PasId { get; set; }
}
