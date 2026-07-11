namespace DogShelter.Model
{
    public static class ValidationMessages
    {
        // Auth / korisnik
        public const string NameRequired = "Ime je obavezno";
        public const string NameMinLength = "Ime mora imati najmanje 2 znaka";
        public const string SurnameRequired = "Prezime je obavezno";
        public const string SurnameMinLength = "Prezime mora imati najmanje 2 znaka";
        public const string EmailRequired = "Email je obavezan";
        public const string EmailInvalid = "Unesite ispravnu email adresu";
        public const string UsernameRequired = "Korisničko ime je obavezno";
        public const string UsernameMinLength = "Korisničko ime mora imati najmanje 3 znaka";
        public const string PasswordRequired = "Lozinka je obavezna";
        public const string PasswordMinLength = "Lozinka mora imati najmanje 6 znakova";
        public const string PasswordConfirmRequired = "Potvrda lozinke je obavezna";
        public const string PasswordsDoNotMatch = "Lozinke se ne podudaraju";
        public const string OldPasswordRequired = "Trenutna lozinka je obavezna";
        public const string OldPasswordIncorrect = "Trenutna lozinka nije ispravna";
        public const string ResetCodeRequired = "Reset kod je obavezan";
        public const string ResetCodeFormat = "Reset kod mora imati točno 6 brojeva";
        public const string NewPasswordRequired = "Nova lozinka je obavezna";
        // ZahtjevZaUdomljavanje
        public const string PasIdRequired = "Pas je obavezan.";
        public const string NapomenaMaxLength = "Napomena može imati najviše 1000 karaktera.";
        public const string RazlogOdbijanjaRequired = "Razlog odbijanja je obavezan.";
        public const string RazlogOdbijanjaMaxLength = "Razlog odbijanja može imati najviše 1000 karaktera.";
        // Posjeta
        public const string KorisnikIdRequired = "Korisnik je obavezan.";
        public const string RazlogOtkazivanjaRequired = "Razlog otkazivanja je obavezan.";
        public const string RazlogOtkazivanjaMaxLength = "Razlog otkazivanja može imati najviše 1000 karaktera.";
        // Paginacija
        public const string PageMin = "Stranica mora biti najmanje 1";
        public const string PageSizeRange = "Veličina stranice mora biti između 1 i 100";
        public const string UsernameFilterMaxLength = "Filter korisničkog imena može imati najviše 100 znakova";
    }
}
