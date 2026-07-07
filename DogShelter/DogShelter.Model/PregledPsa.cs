namespace DogShelter.Model;

public class PregledPsa
{
    public int PregledPsaId { get; set; }
    public int KorisnikId { get; set; }
    public int PasId { get; set; }
    public DateTime DatumPregleda { get; set; }
}
