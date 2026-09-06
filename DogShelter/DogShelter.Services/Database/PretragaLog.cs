using DogShelter.Model;

namespace DogShelter.Services.Database;

/// <summary>
/// One row per dog search a logged-in user runs with at least one filter set - the "korišteni
/// filteri" signal the recommender needs per the prijava. Written by PretragaLogService, read only
/// by PreporukaService; nothing else in the app lists or manages these rows.
/// </summary>
public partial class PretragaLog
{
    public int PretragaLogId { get; set; }

    public int KorisnikId { get; set; }

    public int? RasaId { get; set; }

    public int? VelicinaPsaId { get; set; }

    public Spol? Spol { get; set; }

    public int? NivoAktivnostiId { get; set; }

    public DateTime DatumPretrage { get; set; }

    public virtual Korisnik Korisnik { get; set; } = null!;

    public virtual Rasa? Rasa { get; set; }

    public virtual VelicinaPsa? VelicinaPsa { get; set; }

    public virtual NivoAktivnosti? NivoAktivnosti { get; set; }
}
