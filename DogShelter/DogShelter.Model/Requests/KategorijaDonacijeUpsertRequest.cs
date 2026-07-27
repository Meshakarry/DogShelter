using System.ComponentModel.DataAnnotations;

namespace DogShelter.Model.Requests;

public class KategorijaDonacijeUpsertRequest
{
    [Required]
    [MaxLength(100)]
    public string Naziv { get; set; } = null!;

    [Required]
    [MaxLength(50)]
    public string IkonaKljuc { get; set; } = null!;
}
