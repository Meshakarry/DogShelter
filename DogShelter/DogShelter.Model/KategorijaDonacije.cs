namespace DogShelter.Model;

public class KategorijaDonacije
{
    public int KategorijaDonacijeId { get; set; }
    public string Naziv { get; set; } = null!;
    public string IkonaKljuc { get; set; } = null!;
    public int? PodrazumijevanaJedinicaMjereId { get; set; }

    // Empty means unrestricted (e.g. "Ostalo") - the client should then allow any unit.
    public List<JedinicaMjere> DozvoljeneJedinice { get; set; } = [];
}
