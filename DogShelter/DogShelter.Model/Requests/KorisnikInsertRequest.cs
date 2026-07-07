using System.ComponentModel.DataAnnotations;

namespace DogShelter.Model.Requests
{
    public partial class KorisnikInsertRequest
    {
        public string Ime { get; set; } = null!;

        public string Prezime { get; set; } = null!;

        public string Email { get; set; } = null!;

        public string? Telefon { get; set; }

        public int? GradId { get; set; }

        public string? Adresa { get; set; }

        public string KorisnickoIme { get; set; } = null!;
        public string? SlikaPutanja { get; set; }

        public string Lozinka { get; set; } = null!;

        [Compare("Lozinka", ErrorMessage = "Passwords do not match.")]
        public string LozinkaPotvrda { get; set; } = null!;

        public List<string> Uloge { get; set; } = new();
    }
}
