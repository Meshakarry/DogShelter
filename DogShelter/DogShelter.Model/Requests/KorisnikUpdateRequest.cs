namespace DogShelter.Model.Requests
{
    public partial class KorisnikUpdateRequest
    {
        public string Ime { get; set; } = null!;

        public string Prezime { get; set; } = null!;

        public string? Email { get; set; }

        public string? KorisnickoIme { get; set; }

        public string? Telefon { get; set; }

        public int? GradId { get; set; }

        public string? Adresa { get; set; }

        public string? SlikaPutanja { get; set; }

        public bool? Status { get; set; }

        public string? Lozinka { get; set; }

        public string? LozinkaPotvrda { get; set; }

        public List<string> Uloge { get; set; } = new();

        public List<string> UlogeZaBrisanje { get; set; } = new();
    }
}
