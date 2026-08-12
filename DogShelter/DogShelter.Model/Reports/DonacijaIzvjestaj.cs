namespace DogShelter.Model.Reports;

public class DonacijaIzvjestaj
{
    public DateTime? DatumOd { get; set; }
    public DateTime? DatumDo { get; set; }
    public List<MjesecDonacijaStavka> NovcanePoMjesecima { get; set; } = [];
    public int UkupnoBrojNovcanih { get; set; }
    public decimal UkupanIznos { get; set; }
    public List<StatusBrojStavka> NovcanoPoStatusu { get; set; } = [];
    public List<StatusBrojStavka> MaterijalnoPoStatusu { get; set; } = [];
    public int UkupnoSvih { get; set; }
}

public class MjesecDonacijaStavka
{
    public int Godina { get; set; }
    public int Mjesec { get; set; }
    public string MjesecNaziv { get; set; } = string.Empty;
    public int Broj { get; set; }
    public decimal Iznos { get; set; }
}

public class StatusBrojStavka
{
    public string Status { get; set; } = string.Empty;
    public int Broj { get; set; }
}
