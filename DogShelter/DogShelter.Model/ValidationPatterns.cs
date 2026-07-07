namespace DogShelter.Model
{
    public static class ValidationPatterns
    {
        public const string Phone = @"^\d{9}$";
        public const string PhoneErrorMessage = "Unesite ispravan broj telefona (9 brojeva)";
    }
}
