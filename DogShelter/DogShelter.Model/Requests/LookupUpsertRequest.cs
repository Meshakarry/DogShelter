using System.ComponentModel.DataAnnotations;

namespace DogShelter.Model.Requests
{
    public class LookupUpsertRequest
    {
        [Required]
        [MaxLength(100)]
        public string Naziv { get; set; } = null!;
    }
}
