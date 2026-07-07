namespace DogShelter.Services.Database;

public partial class AktivnostVolontera
{
    public int AktivnostVolonteraId { get; set; }

    public int VolonterId { get; set; }

    public int TipAktivnostiId { get; set; }

    public DateOnly DatumAktivnosti { get; set; }

    public decimal BrojSati { get; set; }

    public string? Opis { get; set; }

    public virtual TipAktivnosti TipAktivnosti { get; set; } = null!;

    public virtual Volonter Volonter { get; set; } = null!;
}
