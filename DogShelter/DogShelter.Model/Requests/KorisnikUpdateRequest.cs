namespace DogShelter.Model.Requests
{
    public partial class KorisnikUpdateRequest
    {
        public string Ime { get; set; } = null!;

        public string Prezime { get; set; } = null!;

        public string? Email { get; set; }

        public string? Telefon { get; set; }

        public bool? Status { get; set; }
        public string? SlikaPutanja { get; set; }
    }
}
