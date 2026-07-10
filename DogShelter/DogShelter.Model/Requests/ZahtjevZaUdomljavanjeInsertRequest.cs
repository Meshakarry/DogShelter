using System.ComponentModel.DataAnnotations;

namespace DogShelter.Model.Requests;

public class ZahtjevZaUdomljavanjeInsertRequest
{
    [Required(ErrorMessage = "Pas je obavezan.")]
    public int PasId { get; set; }

    [MaxLength(1000, ErrorMessage = "Napomena može imati najviše 1000 karaktera.")]
    public string? Napomena { get; set; }
}
