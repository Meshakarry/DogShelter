using System.ComponentModel.DataAnnotations;

namespace DogShelter.Model.Requests
{
    public class RequestPasswordResetRequest
    {
        [Required(ErrorMessage = ValidationMessages.EmailRequired)]
        [EmailAddress(ErrorMessage = ValidationMessages.EmailInvalid)]
        public string Email { get; set; } = null!;
    }
}
