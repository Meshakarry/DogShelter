using System.ComponentModel.DataAnnotations;

namespace DogShelter.Model.Requests;

public class DonacijaStavkaRequest
{
    [Required]
    public int KategorijaDonacijeId { get; set; }

    [MaxLength(200, ErrorMessage = ValidationMessages.PrilagodjenNazivMaxLength)]
    public string? PrilagodjenNaziv { get; set; }

    [Range(0.01, 100000, ErrorMessage = ValidationMessages.KolicinaRange)]
    public decimal Kolicina { get; set; }

    [Required]
    public int JedinicaMjereId { get; set; }
}
