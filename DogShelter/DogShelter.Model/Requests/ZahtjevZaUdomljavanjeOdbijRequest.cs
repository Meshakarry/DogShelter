using System.ComponentModel.DataAnnotations;

namespace DogShelter.Model.Requests;

public class ZahtjevZaUdomljavanjeOdbijRequest
{
    [Required(ErrorMessage = "Razlog odbijanja je obavezan.")]
    [MaxLength(1000, ErrorMessage = "Razlog odbijanja može imati najviše 1000 karaktera.")]
    public string RazlogOdbijanja { get; set; } = null!;
}
