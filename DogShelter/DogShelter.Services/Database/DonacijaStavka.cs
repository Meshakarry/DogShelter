namespace DogShelter.Services.Database;

/// <summary>One donated item line within a Materijalna Donacija.</summary>
public partial class DonacijaStavka
{
    public int DonacijaStavkaId { get; set; }

    public int DonacijaId { get; set; }

    public int KategorijaDonacijeId { get; set; }

    public string? PrilagodjenNaziv { get; set; }

    public decimal Kolicina { get; set; }

    public int JedinicaMjereId { get; set; }

    public virtual Donacija Donacija { get; set; } = null!;

    public virtual KategorijaDonacije KategorijaDonacije { get; set; } = null!;

    public virtual JedinicaMjere JedinicaMjere { get; set; } = null!;
}
