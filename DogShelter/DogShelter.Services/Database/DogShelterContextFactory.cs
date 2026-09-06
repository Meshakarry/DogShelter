using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace DogShelter.Services.Database;

/// <summary>
/// Design-time only: used by EF Core tooling (<c>dotnet ef migrations</c> / <c>database update</c>)
/// when it can't build the application host. Reads the connection string from <c>.env</c> - the
/// exact same source the API and Worker use at runtime - so the connection string is never
/// hardcoded anywhere. Not used when the application runs; the host configures the context from
/// <c>IConfiguration</c> in <c>Program.cs</c>.
/// </summary>
public class DogShelterContextFactory : IDesignTimeDbContextFactory<DogShelterContext>
{
    public DogShelterContext CreateDbContext(string[] args)
    {
        DotNetEnv.Env.TraversePath().Load();

        var connectionString = Environment.GetEnvironmentVariable("ConnectionStrings__DogShelter")
            ?? throw new InvalidOperationException(
                "ConnectionStrings__DogShelter nije postavljen. Provjerite da .env postoji u projektu " +
                "(raspakujte DogShelter/.env-tajne.zip, šifra: fit).");

        var options = new DbContextOptionsBuilder<DogShelterContext>()
            .UseSqlServer(connectionString)
            .Options;

        return new DogShelterContext(options);
    }
}
