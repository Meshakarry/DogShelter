using System.ComponentModel.DataAnnotations;

namespace DogShelter.Model.Requests;

public class PosjetaAdminInsertRequest
{
    [Required(ErrorMessage = ValidationMessages.KorisnikIdRequired)]
    public int KorisnikId { get; set; }

    public DateTime DatumVrijeme { get; set; }

    public int? PasId { get; set; }

    [MaxLength(1000, ErrorMessage = ValidationMessages.NapomenaMaxLength)]
    public string? Napomena { get; set; }
}
