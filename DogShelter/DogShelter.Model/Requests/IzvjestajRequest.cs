using System.ComponentModel.DataAnnotations;

namespace DogShelter.Model.Requests;

public class IzvjestajRequest : IValidatableObject
{
    public DateTime? DatumOd { get; set; }
    public DateTime? DatumDo { get; set; }

    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        if (DatumOd.HasValue && DatumDo.HasValue && DatumDo.Value < DatumOd.Value)
        {
            yield return new ValidationResult(
                "DatumDo mora biti jednak ili nakon DatumOd.",
                [nameof(DatumDo)]);
        }
    }
}
