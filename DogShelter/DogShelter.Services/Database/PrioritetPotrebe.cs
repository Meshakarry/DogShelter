namespace DogShelter.Services.Database;

public partial class PrioritetPotrebe
{
    public int PrioritetPotrebeId { get; set; }

    public string Naziv { get; set; } = null!;

    public virtual ICollection<PotrebaAzila> PotrebeAzila { get; set; } = new List<PotrebaAzila>();
}
