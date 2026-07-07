namespace DogShelter.Services.Database;

public partial class TipAktivnosti
{
    public int TipAktivnostiId { get; set; }

    public string Naziv { get; set; } = null!;

    public virtual ICollection<AktivnostVolontera> AktivnostVolonteras { get; set; } = new List<AktivnostVolontera>();
}
