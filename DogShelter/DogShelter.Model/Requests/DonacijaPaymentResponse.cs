namespace DogShelter.Model.Requests;

public class DonacijaPaymentResponse
{
    public Donacija Donacija { get; set; } = null!;
    public string? ClientSecret { get; set; }
}
