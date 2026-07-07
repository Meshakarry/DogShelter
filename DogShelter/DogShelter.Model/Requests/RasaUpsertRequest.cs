using System.ComponentModel.DataAnnotations;

namespace DogShelter.Model.Requests
{
    public class RasaUpsertRequest
    {
        [Required]
        [MaxLength(100)]
        public string Naziv { get; set; } = null!;

        public bool Aktivan { get; set; } = true;
    }
}
