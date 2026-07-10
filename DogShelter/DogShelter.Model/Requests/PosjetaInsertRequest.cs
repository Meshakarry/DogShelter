using System.ComponentModel.DataAnnotations;

namespace DogShelter.Model.Requests;

public class PosjetaInsertRequest
{
    public DateTime DatumVrijeme { get; set; }

    public int? PasId { get; set; }

    [MaxLength(1000, ErrorMessage = ValidationMessages.NapomenaMaxLength)]
    public string? Napomena { get; set; }
}
