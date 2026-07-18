using System.ComponentModel.DataAnnotations;

namespace DogShelter.Model.Requests;

public class ObavijestUpdateRequest
{
    [Required, MaxLength(200)]
    public string Naslov { get; set; } = null!;

    [Required]
    public string Sadrzaj { get; set; } = null!;

    public bool Aktivna { get; set; }
}
