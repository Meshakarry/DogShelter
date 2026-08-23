namespace DogShelter.Services.Database;

public partial class JedinicaMjere
{
    public int JedinicaMjereId { get; set; }

    public string Naziv { get; set; } = null!;

    public virtual ICollection<DonacijaStavka> DonacijaStavke { get; set; } = new List<DonacijaStavka>();
}
