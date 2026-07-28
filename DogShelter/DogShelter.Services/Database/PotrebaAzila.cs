namespace DogShelter.Services.Database;

public partial class PotrebaAzila
{
    public int PotrebaAzilaId { get; set; }

    public string Naziv { get; set; } = null!;

    public string Opis { get; set; } = null!;

    public int PrioritetPotrebeId { get; set; }

    public string IkonaKljuc { get; set; } = null!;

    public bool Aktivna { get; set; }

    public DateTime DatumKreiranja { get; set; }

    public virtual PrioritetPotrebe PrioritetPotrebe { get; set; } = null!;
}
