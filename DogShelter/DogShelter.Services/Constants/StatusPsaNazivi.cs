namespace DogShelter.Services.Constants;

public static class StatusPsaNazivi
{
    public const string Dostupan = "Dostupan";

    // Set when an adoption request is approved (ZahtjevZaUdomljavanjeService.Odobri) - the dog is
    // no longer available to other users, but the adoption isn't final yet. FinalizirajUdomljenje
    // is the only transition from here to Udomljen. Matches the prijava's literal three-stage
    // flow ("dostupan, rezervisan, udomljen"), not a same-transaction skip from Dostupan straight
    // to Udomljen.
    public const string Rezervisan = "Rezervisan";

    public const string Udomljen = "Udomljen";
}
