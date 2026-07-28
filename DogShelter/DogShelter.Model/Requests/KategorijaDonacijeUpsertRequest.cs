using System.ComponentModel.DataAnnotations;

namespace DogShelter.Model.Requests;

public class KategorijaDonacijeUpsertRequest
{
    [Required]
    [MaxLength(100)]
    public string Naziv { get; set; } = null!;

    [Required]
    [MaxLength(50)]
    public string IkonaKljuc { get; set; } = null!;

    public int? PodrazumijevanaJedinicaMjereId { get; set; }

    // Empty/null means unrestricted - the client shows every unit for this category.
    public List<int>? DozvoljeneJediniceIds { get; set; }
}
