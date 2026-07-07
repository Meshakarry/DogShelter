using System.ComponentModel.DataAnnotations;

namespace DogShelter.Model.Requests
{
    public class KorisnikProfileUpdateRequest
    {
        [Required(ErrorMessage = ValidationMessages.NameRequired)]
        [MinLength(2, ErrorMessage = ValidationMessages.NameMinLength)]
        public string Ime { get; set; } = null!;

        [Required(ErrorMessage = ValidationMessages.SurnameRequired)]
        [MinLength(2, ErrorMessage = ValidationMessages.SurnameMinLength)]
        public string Prezime { get; set; } = null!;

        [Required(ErrorMessage = ValidationMessages.EmailRequired)]
        [EmailAddress(ErrorMessage = ValidationMessages.EmailInvalid)]
        public string Email { get; set; } = null!;

        [RegularExpression(ValidationPatterns.Phone, ErrorMessage = ValidationPatterns.PhoneErrorMessage)]
        public string? Telefon { get; set; }

        [Required(ErrorMessage = ValidationMessages.UsernameRequired)]
        [MinLength(3, ErrorMessage = ValidationMessages.UsernameMinLength)]
        public string KorisnickoIme { get; set; } = null!;

        public string? SlikaPutanja { get; set; }
    }
}
