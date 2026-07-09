using System.ComponentModel.DataAnnotations;

namespace DogShelter.Model.Requests;

public class PregledPsaInsertRequest
{
    [Required]
    public int PasId { get; set; }
}
