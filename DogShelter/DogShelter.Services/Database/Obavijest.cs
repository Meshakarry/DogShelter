namespace DogShelter.Services.Database;

public partial class Obavijest
{
    public int ObavijestId { get; set; }

    public string Naslov { get; set; } = null!;

    public string Sadrzaj { get; set; } = null!;

    public string SlikaPutanja { get; set; } = null!;

    public DateTime DatumObjave { get; set; }

    public int AutorId { get; set; }

    public bool Aktivna { get; set; }

    public virtual Korisnik Autor { get; set; } = null!;
}
