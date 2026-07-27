using System.ComponentModel.DataAnnotations;

namespace DogShelter.Model.Requests;

public class PotrebaAzilaUpdateRequest
{
    [Required(ErrorMessage = "Naziv potrebe je obavezan.")]
    [MaxLength(150, ErrorMessage = "Naziv potrebe može imati najviše 150 karaktera.")]
    public string Naziv { get; set; } = null!;

    [Required(ErrorMessage = "Opis potrebe je obavezan.")]
    [MaxLength(500, ErrorMessage = "Opis potrebe može imati najviše 500 karaktera.")]
    public string Opis { get; set; } = null!;

    [Required(ErrorMessage = "Prioritet je obavezan.")]
    public int PrioritetPotrebeId { get; set; }

    [Required(ErrorMessage = "Ikona je obavezna.")]
    [MaxLength(50)]
    public string IkonaKljuc { get; set; } = null!;

    public bool Aktivna { get; set; }
}
