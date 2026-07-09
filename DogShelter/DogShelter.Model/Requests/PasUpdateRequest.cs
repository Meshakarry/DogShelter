using System.ComponentModel.DataAnnotations;

namespace DogShelter.Model.Requests;

public class PasUpdateRequest
{
    [Required, MaxLength(100)]
    public string Naziv { get; set; } = null!;

    [Required]
    public int RasaId { get; set; }

    public Spol Spol { get; set; }

    public DateOnly? DatumRodjenja { get; set; }

    [MaxLength(2000)]
    public string? Opis { get; set; }

    [Required]
    public int StatusPsaId { get; set; }

    [Required]
    public int VelicinaPsaId { get; set; }

    [Range(0.1, 200)]
    public decimal? Tezina { get; set; }

    public DateOnly DatumPrijema { get; set; }

    public bool Vakcinisan { get; set; }

    public bool Sterilizovan { get; set; }

    public bool Aktivan { get; set; }
}
