namespace DogShelter.Model;

public class DonacijaStavka
{
    public int DonacijaStavkaId { get; set; }
    public int KategorijaDonacijeId { get; set; }
    public string? KategorijaDonacijeNaziv { get; set; }
    public string? PrilagodjenNaziv { get; set; }
    public decimal Kolicina { get; set; }
    public int JedinicaMjereId { get; set; }
    public string? JedinicaMjereNaziv { get; set; }
}
