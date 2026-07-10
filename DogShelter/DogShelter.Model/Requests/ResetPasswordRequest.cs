using System.ComponentModel.DataAnnotations;

namespace DogShelter.Model.Requests
{
    public class ResetPasswordRequest
    {
        [Required(ErrorMessage = ValidationMessages.EmailRequired)]
        [EmailAddress(ErrorMessage = ValidationMessages.EmailInvalid)]
        public string Email { get; set; } = null!;

        [Required(ErrorMessage = ValidationMessages.ResetCodeRequired)]
        [RegularExpression(@"^\d{6}$", ErrorMessage = ValidationMessages.ResetCodeFormat)]
        public string Kod { get; set; } = null!;

        [Required(ErrorMessage = ValidationMessages.NewPasswordRequired)]
        [MinLength(6, ErrorMessage = ValidationMessages.PasswordMinLength)]
        public string NovaLozinka { get; set; } = null!;

        [Required(ErrorMessage = ValidationMessages.PasswordConfirmRequired)]
        [Compare(nameof(NovaLozinka), ErrorMessage = ValidationMessages.PasswordsDoNotMatch)]
        public string NovaLozinkaPotvrda { get; set; } = null!;
    }
}
