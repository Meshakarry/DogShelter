namespace DogShelter.Model;

public class SlikaPsa
{
    public int SlikaPsaId { get; set; }
    public int PasId { get; set; }
    public string Putanja { get; set; } = null!;
    public int RedniBroj { get; set; }
}
