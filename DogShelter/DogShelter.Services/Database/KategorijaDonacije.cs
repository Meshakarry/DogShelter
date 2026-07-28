namespace DogShelter.Services.Database;

public partial class KategorijaDonacije
{
    public int KategorijaDonacijeId { get; set; }

    public string Naziv { get; set; } = null!;

    public string IkonaKljuc { get; set; } = null!;

    public int? PodrazumijevanaJedinicaMjereId { get; set; }

    public virtual ICollection<Donacija> Donacijas { get; set; } = new List<Donacija>();

    public virtual JedinicaMjere? PodrazumijevanaJedinicaMjere { get; set; }

    // Empty means unrestricted (e.g. "Ostalo") - the mobile form falls back to showing every unit.
    public virtual ICollection<JedinicaMjere> DozvoljeneJedinice { get; set; } = new List<JedinicaMjere>();
}
