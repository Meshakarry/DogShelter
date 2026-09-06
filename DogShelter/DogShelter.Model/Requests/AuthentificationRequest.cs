using System.ComponentModel.DataAnnotations;

namespace DogShelter.Model.Requests
{
    public class AuthenticationRequest
    {
        [Required(ErrorMessage = ValidationMessages.UsernameRequired)]
        public string KorisnickoIme { get; set; } = null!;

        [Required(ErrorMessage = ValidationMessages.PasswordRequired)]
        public string Lozinka { get; set; } = null!;
    }
}
