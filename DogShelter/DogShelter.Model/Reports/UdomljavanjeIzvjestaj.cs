namespace DogShelter.Model.Reports;

public class UdomljavanjeIzvjestaj
{
    public DateTime? DatumOd { get; set; }
    public DateTime? DatumDo { get; set; }
    public List<RasaBrojStavka> NajcescePoRasi { get; set; } = [];
    public List<MjesecBrojStavka> PoMjesecima { get; set; } = [];
    public int Ukupno { get; set; }
}

public class RasaBrojStavka
{
    public string Rasa { get; set; } = string.Empty;
    public int Broj { get; set; }
}

public class MjesecBrojStavka
{
    public int Godina { get; set; }
    public int Mjesec { get; set; }
    public string MjesecNaziv { get; set; } = string.Empty;
    public int Broj { get; set; }
}
