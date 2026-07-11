using DogShelter.Model;

namespace DogShelter.Services.Database;

public partial class Pas
{
    public int PasId { get; set; }

    public string Naziv { get; set; } = null!;

    public int RasaId { get; set; }

    public Spol Spol { get; set; }

    public DateOnly? DatumRodjenja { get; set; }

    public string? Opis { get; set; }

    public int StatusPsaId { get; set; }

    public int VelicinaPsaId { get; set; }

    public decimal? Tezina { get; set; }

    public DateOnly DatumPrijema { get; set; }

    public string? SlikaNaslovna { get; set; }

    public bool Vakcinisan { get; set; }

    public bool Sterilizovan { get; set; }

    public bool Aktivan { get; set; }

    public virtual ICollection<PregledPsa> PregledPsas { get; set; } = new List<PregledPsa>();

    public virtual ICollection<Posjeta> Posjetas { get; set; } = new List<Posjeta>();

    public virtual Rasa Rasa { get; set; } = null!;

    public virtual ICollection<SlikaPsa> SlikaPsas { get; set; } = new List<SlikaPsa>();

    public virtual StatusPsa StatusPsa { get; set; } = null!;

    public virtual VelicinaPsa VelicinaPsa { get; set; } = null!;

    public virtual ICollection<ZahtjevZaUdomljavanje> ZahtjevZaUdomljavanjes { get; set; } = new List<ZahtjevZaUdomljavanje>();
}
