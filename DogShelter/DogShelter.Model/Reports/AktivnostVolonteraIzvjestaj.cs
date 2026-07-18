namespace DogShelter.Model.Reports;

public class AktivnostVolonteraIzvjestaj
{
    public DateTime? DatumOd { get; set; }
    public DateTime? DatumDo { get; set; }
    public List<MjesecSatiStavka> PoMjesecima { get; set; } = [];
    public int UkupnoAktivnosti { get; set; }
    public decimal UkupnoSati { get; set; }
}

public class MjesecSatiStavka
{
    public int Godina { get; set; }
    public int Mjesec { get; set; }
    public string MjesecNaziv { get; set; } = string.Empty;
    public int BrojAktivnosti { get; set; }
    public decimal UkupnoSati { get; set; }
}
