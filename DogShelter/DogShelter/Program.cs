using DogShelter.Filters;
using DogShelter.Security;
using DogShelter.Services.Database;
using DogShelter.Services.Interfaces;
using DogShelter.Services.RabbitMq;
using DogShelter.Services.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using Stripe;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Globalization;
using System.Text;
using System.Text.Json.Serialization;
using System.Threading.RateLimiting;

DotNetEnv.Env.TraversePath().Load();

// MVC's default model binder parses [FromForm]/query values using the ambient thread culture, which on a
// Bosnian-localized machine uses "," as the decimal separator - a plain "11.5" form field then silently
// parses as 115. Pinning to invariant culture keeps decimal/date form binding consistent regardless of the
// host OS locale (found via the desktop app's Pas weight field submitting a real "11.5" over multipart/form-data).
CultureInfo.DefaultThreadCurrentCulture = CultureInfo.InvariantCulture;
CultureInfo.DefaultThreadCurrentUICulture = CultureInfo.InvariantCulture;

var builder = WebApplication.CreateBuilder(args);

StripeConfiguration.ApiKey = builder.Configuration["Stripe:SecretKey"] ?? string.Empty;

builder.Services.AddDbContext<DogShelterContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DogShelter")));

builder.Services.AddControllers(x => x.Filters.Add<ErrorFilter>())
    .ConfigureApiBehaviorOptions(options =>
    {
        options.InvalidModelStateResponseFactory = context =>
            new BadRequestObjectResult(new
            {
                message = "Validation failed.",
                errors = context.ModelState
                    .Where(e => e.Value?.Errors.Count > 0)
                    .ToDictionary(
                        e => e.Key,
                        e => e.Value!.Errors.Select(x => x.ErrorMessage).ToArray())
            });
    })
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.PropertyNameCaseInsensitive = true;
        options.JsonSerializerOptions.ReferenceHandler = ReferenceHandler.IgnoreCycles;
        options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter());
    });

builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    options.OnRejected = async (context, cancellationToken) =>
    {
        context.HttpContext.Response.ContentType = "application/json";
        await context.HttpContext.Response.WriteAsJsonAsync(
            new { message = "Previše pokušaja. Pokušajte ponovo za nekoliko minuta." },
            cancellationToken);
    };

    options.AddPolicy("LoginPolicy", httpContext =>
        RateLimitPartition.GetFixedWindowLimiter(
            partitionKey: httpContext.Connection.RemoteIpAddress?.ToString() ?? "anonymous",
            factory: _ => new FixedWindowRateLimiterOptions
            {
                Window = TimeSpan.FromMinutes(15),
                PermitLimit = 10,
                QueueLimit = 0,
                QueueProcessingOrder = QueueProcessingOrder.OldestFirst
            }
        ));

    options.AddPolicy("PasswordResetPolicy", httpContext =>
        RateLimitPartition.GetFixedWindowLimiter(
            partitionKey: httpContext.Connection.RemoteIpAddress?.ToString() ?? "anonymous",
            factory: _ => new FixedWindowRateLimiterOptions
            {
                Window = TimeSpan.FromMinutes(15),
                PermitLimit = 5,
                QueueLimit = 0,
                QueueProcessingOrder = QueueProcessingOrder.OldestFirst
            }
        ));
});

builder.Services.AddAutoMapper(typeof(DogShelter.Services.Mapper.MappingProfile).Assembly);
builder.Services.AddEndpointsApiExplorer();

builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "DogShelter API", Version = "v1" });
    c.AddSecurityDefinition("bearer", new OpenApiSecurityScheme
    {
        Description = "JWT Authorization header using the Bearer scheme",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT"
    });
    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "bearer"
                }
            },
            new string[] { }
        }
    });
    c.ResolveConflictingActions(apiDescriptions => apiDescriptions.First());
});

builder.Services.AddMemoryCache();

// Services
builder.Services.AddScoped<IKorisnikService, KorisnikService>();
builder.Services.AddScoped<IGradService, GradService>();
builder.Services.AddScoped<IRasaService, RasaService>();
builder.Services.AddScoped<IVelicinaPsaService, VelicinaPsaService>();
builder.Services.AddScoped<IStatusPsaService, StatusPsaService>();
builder.Services.AddScoped<IStatusDonacijeService, StatusDonacijeService>();
builder.Services.AddScoped<IStatusPosjeteService, StatusPosjeteService>();
builder.Services.AddScoped<IStatusZahtjevaService, StatusZahtjevaService>();
builder.Services.AddScoped<ITipDonacijeService, TipDonacijeService>();
builder.Services.AddScoped<IKategorijaDonacijeService, KategorijaDonacijeService>();
builder.Services.AddScoped<IJedinicaMjereService, JedinicaMjereService>();
builder.Services.AddScoped<IPrioritetPotrebeService, PrioritetPotrebeService>();
builder.Services.AddScoped<IUlogaService, UlogaService>();
builder.Services.AddScoped<IPotrebaAzilaService, PotrebaAzilaService>();
builder.Services.AddScoped<ITipAktivnostiService, TipAktivnostiService>();
builder.Services.AddScoped<IPasService, PasService>();
builder.Services.AddScoped<IPregledPsaService, PregledPsaService>();
builder.Services.AddScoped<IZahtjevZaUdomljavanjeService, ZahtjevZaUdomljavanjeService>();
builder.Services.AddScoped<IUdomljavanjeService, UdomljavanjeService>();
builder.Services.AddScoped<IPosjetaService, PosjetaService>();
builder.Services.AddScoped<IDonacijaService, DonacijaService>();
builder.Services.AddScoped<IObavijestService, ObavijestService>();
builder.Services.AddScoped<IVolonterService, VolonterService>();
builder.Services.AddScoped<IDogadjajService, DogadjajService>();
builder.Services.AddScoped<IAktivnostVolonteraService, AktivnostVolonteraService>();
builder.Services.AddScoped<IDogadjajVolonterService, DogadjajVolonterService>();
builder.Services.AddScoped<INotifikacijaService, NotifikacijaService>();
builder.Services.AddScoped<IPreporukaService, PreporukaService>();
builder.Services.AddScoped<IStripePaymentService, StripePaymentService>();
builder.Services.AddScoped<IStripeWebhookService, StripeWebhookService>();
builder.Services.AddScoped<IFileUploadService, FileUploadService>();
builder.Services.AddScoped<IPasswordResetService, PasswordResetService>();
builder.Services.AddScoped<ITokenRevocationService, TokenRevocationService>();
builder.Services.AddRabbitMqMailInfrastructure(connectionClientName: "DogShelter API");
builder.Services.AddScoped<IEmailSender, QueuedEmailSender>();
builder.Services.AddSingleton<IJwtTokenGenerator, JwtTokenGenerator>();

// Authorization policies and resource-based handlers
builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("CanModifyZahtjev", policy =>
        policy.Requirements.Add(new CanModifyZahtjevRequirement()));
    options.AddPolicy("CanModifyPosjeta", policy =>
        policy.Requirements.Add(new CanModifyPosjetaRequirement()));
    options.AddPolicy("CanModifyDonacija", policy =>
        policy.Requirements.Add(new CanModifyDonacijaRequirement()));
    options.AddPolicy("CanModifyVolonter", policy =>
        policy.Requirements.Add(new CanModifyVolonterRequirement()));
    options.AddPolicy("CanModifyAktivnostVolontera", policy =>
        policy.Requirements.Add(new CanModifyAktivnostVolonteraRequirement()));
    options.AddPolicy("CanAccessKorisnik", policy =>
        policy.Requirements.Add(new CanAccessKorisnikRequirement()));
});
builder.Services.AddSingleton<IAuthorizationHandler, CanModifyZahtjevHandler>();
builder.Services.AddSingleton<IAuthorizationHandler, CanModifyPosjetaHandler>();
builder.Services.AddSingleton<IAuthorizationHandler, CanModifyDonacijaHandler>();
builder.Services.AddSingleton<IAuthorizationHandler, CanModifyVolonterHandler>();
builder.Services.AddSingleton<IAuthorizationHandler, CanModifyAktivnostVolonteraHandler>();
builder.Services.AddSingleton<IAuthorizationHandler, CanAccessKorisnikHandler>();

// JWT Authentication
var jwtKey = builder.Configuration["JWTSettings:Key"] ?? string.Empty;
var jwtIssuer = builder.Configuration["JWTSettings:Issuer"] ?? string.Empty;
var jwtAudience = builder.Configuration["JWTSettings:Audience"] ?? string.Empty;

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.MapInboundClaims = false;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = jwtIssuer,
        ValidAudience = jwtAudience,
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
        RoleClaimType = System.Security.Claims.ClaimTypes.Role,
        NameClaimType = System.Security.Claims.ClaimTypes.Name
    };
    options.Events = new JwtBearerEvents
    {
        OnTokenValidated = async context =>
        {
            var jti = context.Principal?.FindFirstValue(JwtRegisteredClaimNames.Jti);
            if (string.IsNullOrEmpty(jti))
            {
                context.Fail("Token je nevažeći.");
                return;
            }

            var revocationService = context.HttpContext.RequestServices.GetRequiredService<ITokenRevocationService>();
            if (await revocationService.IsRevokedAsync(jti))
            {
                context.Fail("Token je opozvan.");
            }
        }
    };
});

var allowedOrigins = builder.Configuration["CORS:AllowedOrigins"]
    ?.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
    ?? [];

builder.Services.AddCors(options =>
{
    options.AddPolicy("DogShelterPolicy", policy =>
        policy.WithOrigins(allowedOrigins)
              .AllowAnyHeader()
              .AllowAnyMethod());
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(c => c.SwaggerEndpoint("/swagger/v1/swagger.json", "DogShelter API"));
}

app.UseRouting();
app.UseStaticFiles();
app.UseCors("DogShelterPolicy");
app.UseAuthentication();
app.UseAuthorization();
app.UseRateLimiter();
app.MapControllers();

using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    var logger = services.GetRequiredService<ILoggerFactory>().CreateLogger("StartupSeeding");
    try
    {
        var context = services.GetRequiredService<DogShelterContext>();
        var config = services.GetRequiredService<IConfiguration>();

        await context.Database.MigrateAsync();

        foreach (var roleName in new[] { "Admin", "Volonter", "Korisnik" })
        {
            if (!await context.Ulogas.AnyAsync(r => r.Naziv == roleName))
            {
                context.Ulogas.Add(new Uloga { Naziv = roleName });
                await context.SaveChangesAsync();
            }
        }

        var adminSeed = config.GetSection("AdminSeed");
        var adminUserName = adminSeed["UserName"] ?? "admin";
        var adminEmail = adminSeed["Email"] ?? "admin@dogshelter.ba";
        var adminPassword = adminSeed["Password"] ?? "Admin123!";

        var adminUser = await context.Korisniks
            .Include(u => u.KorisnikUlogas)
            .FirstOrDefaultAsync(u => u.KorisnickoIme == adminUserName);

        if (adminUser == null)
        {
            adminUser = new Korisnik
            {
                Ime = "System",
                Prezime = "Administrator",
                Email = adminEmail,
                KorisnickoIme = adminUserName,
                LozinkaHash = KorisnikService.HashPassword(adminPassword),
                LozinkaSalt = string.Empty,
                Aktivan = true
            };
            context.Korisniks.Add(adminUser);
            await context.SaveChangesAsync();
        }

        var adminRole = await context.Ulogas.FirstAsync(r => r.Naziv == "Admin");
        var hasAdminRole = await context.KorisnikUlogas
            .AnyAsync(ur => ur.KorisnikId == adminUser.KorisnikId && ur.UlogaId == adminRole.UlogaId);

        if (!hasAdminRole)
        {
            context.KorisnikUlogas.Add(new KorisnikUloga
            {
                KorisnikId = adminUser.KorisnikId,
                UlogaId = adminRole.UlogaId
            });
            await context.SaveChangesAsync();
        }

        await EnsureTestUserAsync(context, "korisnik", "Test", "Korisnik", "korisnik@dogshelter.ba", "Korisnik");
        await EnsureTestUserAsync(context, "volonter", "Test", "Volonter", "volonter@dogshelter.ba", "Volonter");

        var env = services.GetRequiredService<IWebHostEnvironment>();
        await DatabaseSeeder.SeedAllAsync(context, logger, env.WebRootPath);
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "Error during startup seeding");
    }
}

static async Task EnsureTestUserAsync(DogShelterContext context, string userName, string ime, string prezime, string email, string roleName)
{
    var user = await context.Korisniks.FirstOrDefaultAsync(u => u.KorisnickoIme == userName);
    if (user == null)
    {
        user = new Korisnik
        {
            Ime = ime,
            Prezime = prezime,
            Email = email,
            KorisnickoIme = userName,
            LozinkaHash = KorisnikService.HashPassword("test"),
            LozinkaSalt = string.Empty,
            Aktivan = true
        };
        context.Korisniks.Add(user);
        await context.SaveChangesAsync();
    }

    var role = await context.Ulogas.FirstAsync(r => r.Naziv == roleName);
    var hasRole = await context.KorisnikUlogas
        .AnyAsync(ur => ur.KorisnikId == user.KorisnikId && ur.UlogaId == role.UlogaId);

    if (!hasRole)
    {
        context.KorisnikUlogas.Add(new KorisnikUloga
        {
            KorisnikId = user.KorisnikId,
            UlogaId = role.UlogaId
        });
        await context.SaveChangesAsync();
    }
}

app.Run();
