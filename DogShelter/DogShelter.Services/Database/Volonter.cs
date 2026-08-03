namespace DogShelter.Services.Database;

public partial class Volonter
{
    public int VolonterId { get; set; }

    public int KorisnikId { get; set; }

    public DateOnly DatumPridruzivanja { get; set; }

    public bool Aktivan { get; set; }

    public string? Napomena { get; set; }

    public virtual ICollection<AktivnostVolontera> AktivnostVolonteras { get; set; } = new List<AktivnostVolontera>();

    public virtual ICollection<DogadjajVolonter> DogadjajVolonters { get; set; } = new List<DogadjajVolonter>();

    public virtual Korisnik Korisnik { get; set; } = null!;
}
