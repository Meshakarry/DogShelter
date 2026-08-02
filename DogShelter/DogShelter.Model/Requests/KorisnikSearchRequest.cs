using System.ComponentModel.DataAnnotations;

namespace DogShelter.Model.Requests
{
    public class KorisnikSearchRequest : PagedSearchRequest
    {
        [MaxLength(100, ErrorMessage = ValidationMessages.UsernameFilterMaxLength)]
        public string? KorisnickoIme { get; set; }
        public int? UlogaId { get; set; }
        public bool? Aktivan { get; set; }
    }
}
