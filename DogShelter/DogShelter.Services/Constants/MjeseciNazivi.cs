namespace DogShelter.Services.Constants;

public static class MjeseciNazivi
{
    private static readonly string[] Nazivi =
        ["Januar", "Februar", "Mart", "April", "Maj", "Juni", "Juli", "August", "Septembar", "Oktobar", "Novembar", "Decembar"];

    public static string Naziv(int mjesec) => Nazivi[mjesec - 1];
}
