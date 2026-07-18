using DogShelter.Filters;
using DogShelter.Security;
using DogShelter.Services.Database;
using DogShelter.Services.Interfaces;
using DogShelter.Services.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using Stripe;
using System.Text;
using System.Text.Json.Serialization;
using System.Threading.RateLimiting;

DotNetEnv.Env.TraversePath().Load();

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
builder.Services.AddScoped<IStripePaymentService, StripePaymentService>();
builder.Services.AddScoped<IStripeWebhookService, StripeWebhookService>();
builder.Services.AddScoped<IFileUploadService, FileUploadService>();
builder.Services.AddScoped<IPasswordResetService, PasswordResetService>();
builder.Services.AddScoped<IEmailSender, SmtpEmailSender>();
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
});
builder.Services.AddSingleton<IAuthorizationHandler, CanModifyZahtjevHandler>();
builder.Services.AddSingleton<IAuthorizationHandler, CanModifyPosjetaHandler>();
builder.Services.AddSingleton<IAuthorizationHandler, CanModifyDonacijaHandler>();
builder.Services.AddSingleton<IAuthorizationHandler, CanModifyVolonterHandler>();
builder.Services.AddSingleton<IAuthorizationHandler, CanModifyAktivnostVolonteraHandler>();

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
