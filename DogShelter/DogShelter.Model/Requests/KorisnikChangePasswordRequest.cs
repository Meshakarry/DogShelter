using System.ComponentModel.DataAnnotations;

namespace DogShelter.Model.Requests
{
    public class KorisnikChangePasswordRequest
    {
        [Required(ErrorMessage = ValidationMessages.OldPasswordRequired)]
        public string StaraLozinka { get; set; } = null!;

        [Required(ErrorMessage = ValidationMessages.PasswordRequired)]
        [MinLength(6, ErrorMessage = ValidationMessages.PasswordMinLength)]
        public string NovaLozinka { get; set; } = null!;

        [Required(ErrorMessage = ValidationMessages.PasswordConfirmRequired)]
        [Compare(nameof(NovaLozinka), ErrorMessage = ValidationMessages.PasswordsDoNotMatch)]
        public string NovaLozinkaPotvrda { get; set; } = null!;
    }
}
