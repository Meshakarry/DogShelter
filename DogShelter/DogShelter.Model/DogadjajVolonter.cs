namespace DogShelter.Model;

public class DogadjajVolonter
{
    public int DogadjajVolonterId { get; set; }
    public int DogadjajId { get; set; }
    public string? DogadjajNaziv { get; set; }
    public DateTime? DogadjajDatum { get; set; }
    public string? DogadjajLokacija { get; set; }
    public int VolonterId { get; set; }
    public int KorisnikId { get; set; }
    public string? VolonterIme { get; set; }
    public string? VolonterPrezime { get; set; }
}
