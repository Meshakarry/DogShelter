namespace DogShelter.Model;

public class Korisnik
{
    public int KorisnikId { get; set; }
    public string Ime { get; set; } = null!;
    public string Prezime { get; set; } = null!;
    public string Email { get; set; } = null!;
    public string? Telefon { get; set; }
    public int? GradId { get; set; }
    public string? Adresa { get; set; }
    public string KorisnickoIme { get; set; } = null!;
    public bool Aktivan { get; set; }
    public string? SlikaPutanja { get; set; }
    public DateTime DatumRegistracije { get; set; }
    public ICollection<KorisnikUloga> KorisnikUloge { get; set; } = null!;
}
