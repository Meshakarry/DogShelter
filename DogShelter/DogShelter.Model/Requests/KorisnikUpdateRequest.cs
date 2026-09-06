using System.ComponentModel.DataAnnotations;

namespace DogShelter.Model.Requests
{
    public partial class KorisnikUpdateRequest
    {
        [Required(ErrorMessage = ValidationMessages.NameRequired)]
        [MinLength(2, ErrorMessage = ValidationMessages.NameMinLength)]
        public string Ime { get; set; } = null!;

        [Required(ErrorMessage = ValidationMessages.SurnameRequired)]
        [MinLength(2, ErrorMessage = ValidationMessages.SurnameMinLength)]
        public string Prezime { get; set; } = null!;

        // Optional here (admin may leave it unchanged), but must be a valid email when provided -
        // EmailAddressAttribute (like every other attribute below except Required) treats null/empty
        // as valid and only checks format once a value is actually present.
        [EmailAddress(ErrorMessage = ValidationMessages.EmailInvalid)]
        public string? Email { get; set; }

        [MinLength(3, ErrorMessage = ValidationMessages.UsernameMinLength)]
        public string? KorisnickoIme { get; set; }

        [RegularExpression(ValidationPatterns.Phone, ErrorMessage = ValidationPatterns.PhoneErrorMessage)]
        public string? Telefon { get; set; }

        public int? GradId { get; set; }

        public string? Adresa { get; set; }

        public bool? Status { get; set; }

        [MinLength(6, ErrorMessage = ValidationMessages.PasswordMinLength)]
        public string? Lozinka { get; set; }

        // Compare treats null == null as a match, so this stays optional alongside Lozinka above.
        [Compare(nameof(Lozinka), ErrorMessage = ValidationMessages.PasswordsDoNotMatch)]
        public string? LozinkaPotvrda { get; set; }

        public List<string> Uloge { get; set; } = new();

        public List<string> UlogeZaBrisanje { get; set; } = new();
    }
}
