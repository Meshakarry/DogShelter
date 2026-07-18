using System.ComponentModel.DataAnnotations;

namespace DogShelter.Model.Requests;

public class DogadjajInsertRequest
{
    [Required(ErrorMessage = ValidationMessages.DogadjajNazivRequired)]
    [MaxLength(150, ErrorMessage = ValidationMessages.DogadjajNazivMaxLength)]
    public string Naziv { get; set; } = null!;

    [MaxLength(2000, ErrorMessage = ValidationMessages.DogadjajOpisMaxLength)]
    public string? Opis { get; set; }

    [Required(ErrorMessage = ValidationMessages.DogadjajDatumRequired)]
    public DateTime Datum { get; set; }

    [Required(ErrorMessage = ValidationMessages.DogadjajLokacijaRequired)]
    [MaxLength(200, ErrorMessage = ValidationMessages.DogadjajLokacijaMaxLength)]
    public string Lokacija { get; set; } = null!;

    public bool Aktivan { get; set; } = true;
}
