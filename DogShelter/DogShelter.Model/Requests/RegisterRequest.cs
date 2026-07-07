using System.ComponentModel.DataAnnotations;
using DogShelter.Model;

namespace DogShelter.Model.Requests
{
    public class RegisterRequest
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

        [Required(ErrorMessage = ValidationMessages.PasswordRequired)]
        [MinLength(6, ErrorMessage = ValidationMessages.PasswordMinLength)]
        public string Lozinka { get; set; } = null!;

        [Compare(nameof(Lozinka), ErrorMessage = ValidationMessages.PasswordsDoNotMatch)]
        public string LozinkaPotvrda { get; set; } = null!;

        public string? SlikaPutanja { get; set; }
    }
}
