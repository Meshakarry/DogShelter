using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace DogShelter.Services.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Dogadjaj",
                columns: table => new
                {
                    DogadjajId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Naziv = table.Column<string>(type: "nvarchar(150)", maxLength: 150, nullable: false),
                    Opis = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    Datum = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Lokacija = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    Aktivan = table.Column<bool>(type: "bit", nullable: false, defaultValue: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Dogadjaj", x => x.DogadjajId);
                });

            migrationBuilder.CreateTable(
                name: "Grad",
                columns: table => new
                {
                    GradId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Naziv = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    PostanskiBroj = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Grad", x => x.GradId);
                });

            migrationBuilder.CreateTable(
                name: "Rasa",
                columns: table => new
                {
                    RasaId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Naziv = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Aktivan = table.Column<bool>(type: "bit", nullable: false, defaultValue: true)
                        .Annotation("Relational:DefaultConstraintName", "DF_Rasa_Aktivan")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Rasa", x => x.RasaId);
                });

            migrationBuilder.CreateTable(
                name: "StatusDonacije",
                columns: table => new
                {
                    StatusDonacijeId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Naziv = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_StatusDonacije", x => x.StatusDonacijeId);
                });

            migrationBuilder.CreateTable(
                name: "StatusPosjete",
                columns: table => new
                {
                    StatusPosjeteId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Naziv = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_StatusPosjete", x => x.StatusPosjeteId);
                });

            migrationBuilder.CreateTable(
                name: "StatusPsa",
                columns: table => new
                {
                    StatusPsaId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Naziv = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_StatusPsa", x => x.StatusPsaId);
                });

            migrationBuilder.CreateTable(
                name: "StatusZahtjeva",
                columns: table => new
                {
                    StatusZahtjevaId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Naziv = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_StatusZahtjeva", x => x.StatusZahtjevaId);
                });

            migrationBuilder.CreateTable(
                name: "TipAktivnosti",
                columns: table => new
                {
                    TipAktivnostiId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Naziv = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TipAktivnosti", x => x.TipAktivnostiId);
                });

            migrationBuilder.CreateTable(
                name: "TipDonacije",
                columns: table => new
                {
                    TipDonacijeId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Naziv = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TipDonacije", x => x.TipDonacijeId);
                });

            migrationBuilder.CreateTable(
                name: "Uloga",
                columns: table => new
                {
                    UlogaId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Naziv = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Uloga", x => x.UlogaId);
                });

            migrationBuilder.CreateTable(
                name: "VelicinaPsa",
                columns: table => new
                {
                    VelicinaPsaId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Naziv = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_VelicinaPsa", x => x.VelicinaPsaId);
                });

            migrationBuilder.CreateTable(
                name: "Korisnik",
                columns: table => new
                {
                    KorisnikId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Ime = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Prezime = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Email = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: false),
                    LozinkaHash = table.Column<string>(type: "nvarchar(512)", maxLength: 512, nullable: false),
                    LozinkaSalt = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: false),
                    Telefon = table.Column<string>(type: "nvarchar(30)", maxLength: 30, nullable: true),
                    GradId = table.Column<int>(type: "int", nullable: true),
                    Adresa = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: true),
                    KorisnickoIme = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Aktivan = table.Column<bool>(type: "bit", nullable: false, defaultValue: true)
                        .Annotation("Relational:DefaultConstraintName", "DF_Korisnik_Aktivan"),
                    SlikaPutanja = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    DatumRegistracije = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "(sysdatetime())")
                        .Annotation("Relational:DefaultConstraintName", "DF_Korisnik_DatumRegistracije")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Korisnik", x => x.KorisnikId);
                    table.ForeignKey(
                        name: "FK_Korisnik_Grad",
                        column: x => x.GradId,
                        principalTable: "Grad",
                        principalColumn: "GradId");
                });

            migrationBuilder.CreateTable(
                name: "Pas",
                columns: table => new
                {
                    PasId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Naziv = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    RasaId = table.Column<int>(type: "int", nullable: false),
                    Spol = table.Column<int>(type: "int", nullable: false),
                    DatumRodjenja = table.Column<DateOnly>(type: "date", nullable: true),
                    Opis = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    StatusPsaId = table.Column<int>(type: "int", nullable: false),
                    VelicinaPsaId = table.Column<int>(type: "int", nullable: false),
                    Tezina = table.Column<decimal>(type: "decimal(5,2)", nullable: true),
                    DatumPrijema = table.Column<DateOnly>(type: "date", nullable: false),
                    SlikaNaslovna = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    Vakcinisan = table.Column<bool>(type: "bit", nullable: false),
                    Sterilizovan = table.Column<bool>(type: "bit", nullable: false),
                    Aktivan = table.Column<bool>(type: "bit", nullable: false, defaultValue: true)
                        .Annotation("Relational:DefaultConstraintName", "DF_Pas_Aktivan")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Pas", x => x.PasId);
                    table.ForeignKey(
                        name: "FK_Pas_Rasa",
                        column: x => x.RasaId,
                        principalTable: "Rasa",
                        principalColumn: "RasaId");
                    table.ForeignKey(
                        name: "FK_Pas_Status",
                        column: x => x.StatusPsaId,
                        principalTable: "StatusPsa",
                        principalColumn: "StatusPsaId");
                    table.ForeignKey(
                        name: "FK_Pas_Velicina",
                        column: x => x.VelicinaPsaId,
                        principalTable: "VelicinaPsa",
                        principalColumn: "VelicinaPsaId");
                });

            migrationBuilder.CreateTable(
                name: "Donacija",
                columns: table => new
                {
                    DonacijaId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    KorisnikId = table.Column<int>(type: "int", nullable: false),
                    TipDonacijeId = table.Column<int>(type: "int", nullable: false),
                    StatusDonacijeId = table.Column<int>(type: "int", nullable: false),
                    Iznos = table.Column<decimal>(type: "decimal(18,2)", nullable: true),
                    DatumDonacije = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "(sysdatetime())"),
                    StripePaymentIntentId = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: true),
                    Napomena = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Donacija", x => x.DonacijaId);
                    table.ForeignKey(
                        name: "FK_Donacija_Korisnik",
                        column: x => x.KorisnikId,
                        principalTable: "Korisnik",
                        principalColumn: "KorisnikId");
                    table.ForeignKey(
                        name: "FK_Donacija_Status",
                        column: x => x.StatusDonacijeId,
                        principalTable: "StatusDonacije",
                        principalColumn: "StatusDonacijeId");
                    table.ForeignKey(
                        name: "FK_Donacija_Tip",
                        column: x => x.TipDonacijeId,
                        principalTable: "TipDonacije",
                        principalColumn: "TipDonacijeId");
                });

            migrationBuilder.CreateTable(
                name: "KorisnikUloga",
                columns: table => new
                {
                    KorisnikUlogaId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    KorisnikId = table.Column<int>(type: "int", nullable: false),
                    UlogaId = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_KorisnikUloga", x => x.KorisnikUlogaId);
                    table.ForeignKey(
                        name: "FK_KorisnikUloga_Korisnik",
                        column: x => x.KorisnikId,
                        principalTable: "Korisnik",
                        principalColumn: "KorisnikId");
                    table.ForeignKey(
                        name: "FK_KorisnikUloga_Uloga",
                        column: x => x.UlogaId,
                        principalTable: "Uloga",
                        principalColumn: "UlogaId");
                });

            migrationBuilder.CreateTable(
                name: "Obavijest",
                columns: table => new
                {
                    ObavijestId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Naslov = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    Sadrzaj = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    SlikaPutanja = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    DatumObjave = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "(sysdatetime())"),
                    AutorId = table.Column<int>(type: "int", nullable: false),
                    Aktivna = table.Column<bool>(type: "bit", nullable: false, defaultValue: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Obavijest", x => x.ObavijestId);
                    table.ForeignKey(
                        name: "FK_Obavijest_Autor",
                        column: x => x.AutorId,
                        principalTable: "Korisnik",
                        principalColumn: "KorisnikId");
                });

            migrationBuilder.CreateTable(
                name: "Posjeta",
                columns: table => new
                {
                    PosjetaId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    KorisnikId = table.Column<int>(type: "int", nullable: false),
                    DatumVrijeme = table.Column<DateTime>(type: "datetime2", nullable: false),
                    StatusPosjeteId = table.Column<int>(type: "int", nullable: false),
                    Napomena = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Posjeta", x => x.PosjetaId);
                    table.ForeignKey(
                        name: "FK_Posjeta_Korisnik",
                        column: x => x.KorisnikId,
                        principalTable: "Korisnik",
                        principalColumn: "KorisnikId");
                    table.ForeignKey(
                        name: "FK_Posjeta_Status",
                        column: x => x.StatusPosjeteId,
                        principalTable: "StatusPosjete",
                        principalColumn: "StatusPosjeteId");
                });

            migrationBuilder.CreateTable(
                name: "Volonter",
                columns: table => new
                {
                    VolonterId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    KorisnikId = table.Column<int>(type: "int", nullable: false),
                    DatumPridruzivanja = table.Column<DateOnly>(type: "date", nullable: false),
                    Aktivan = table.Column<bool>(type: "bit", nullable: false, defaultValue: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Volonter", x => x.VolonterId);
                    table.ForeignKey(
                        name: "FK_Volonter_Korisnik",
                        column: x => x.KorisnikId,
                        principalTable: "Korisnik",
                        principalColumn: "KorisnikId");
                });

            migrationBuilder.CreateTable(
                name: "PregledPsa",
                columns: table => new
                {
                    PregledPsaId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    KorisnikId = table.Column<int>(type: "int", nullable: false),
                    PasId = table.Column<int>(type: "int", nullable: false),
                    DatumPregleda = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "(sysdatetime())")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PregledPsa", x => x.PregledPsaId);
                    table.ForeignKey(
                        name: "FK_PregledPsa_Korisnik",
                        column: x => x.KorisnikId,
                        principalTable: "Korisnik",
                        principalColumn: "KorisnikId");
                    table.ForeignKey(
                        name: "FK_PregledPsa_Pas",
                        column: x => x.PasId,
                        principalTable: "Pas",
                        principalColumn: "PasId");
                });

            migrationBuilder.CreateTable(
                name: "SlikaPsa",
                columns: table => new
                {
                    SlikaPsaId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    PasId = table.Column<int>(type: "int", nullable: false),
                    Putanja = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    RedniBroj = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SlikaPsa", x => x.SlikaPsaId);
                    table.ForeignKey(
                        name: "FK_SlikaPsa_Pas",
                        column: x => x.PasId,
                        principalTable: "Pas",
                        principalColumn: "PasId");
                });

            migrationBuilder.CreateTable(
                name: "ZahtjevZaUdomljavanje",
                columns: table => new
                {
                    ZahtjevZaUdomljavanjeId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    KorisnikId = table.Column<int>(type: "int", nullable: false),
                    PasId = table.Column<int>(type: "int", nullable: false),
                    StatusZahtjevaId = table.Column<int>(type: "int", nullable: false),
                    DatumPodnosenja = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "(sysdatetime())"),
                    Napomena = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: true),
                    DatumObrade = table.Column<DateTime>(type: "datetime2", nullable: true),
                    ObradioKorisnikId = table.Column<int>(type: "int", nullable: true),
                    RazlogOdbijanja = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ZahtjevZaUdomljavanje", x => x.ZahtjevZaUdomljavanjeId);
                    table.ForeignKey(
                        name: "FK__ZahtjevZa__Koris__4CA06362",
                        column: x => x.KorisnikId,
                        principalTable: "Korisnik",
                        principalColumn: "KorisnikId");
                    table.ForeignKey(
                        name: "FK__ZahtjevZa__Obrad__4F7CD00D",
                        column: x => x.ObradioKorisnikId,
                        principalTable: "Korisnik",
                        principalColumn: "KorisnikId");
                    table.ForeignKey(
                        name: "FK__ZahtjevZa__PasId__4D94879B",
                        column: x => x.PasId,
                        principalTable: "Pas",
                        principalColumn: "PasId");
                    table.ForeignKey(
                        name: "FK__ZahtjevZa__Statu__4E88ABD4",
                        column: x => x.StatusZahtjevaId,
                        principalTable: "StatusZahtjeva",
                        principalColumn: "StatusZahtjevaId");
                });

            migrationBuilder.CreateTable(
                name: "AktivnostVolontera",
                columns: table => new
                {
                    AktivnostVolonteraId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    VolonterId = table.Column<int>(type: "int", nullable: false),
                    TipAktivnostiId = table.Column<int>(type: "int", nullable: false),
                    DatumAktivnosti = table.Column<DateOnly>(type: "date", nullable: false),
                    BrojSati = table.Column<decimal>(type: "decimal(5,2)", nullable: false),
                    Opis = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AktivnostVolontera", x => x.AktivnostVolonteraId);
                    table.ForeignKey(
                        name: "FK_AktivnostVolontera_Tip",
                        column: x => x.TipAktivnostiId,
                        principalTable: "TipAktivnosti",
                        principalColumn: "TipAktivnostiId");
                    table.ForeignKey(
                        name: "FK_AktivnostVolontera_Volonter",
                        column: x => x.VolonterId,
                        principalTable: "Volonter",
                        principalColumn: "VolonterId");
                });

            migrationBuilder.CreateTable(
                name: "DogadjajVolonter",
                columns: table => new
                {
                    DogadjajVolonterId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    DogadjajId = table.Column<int>(type: "int", nullable: false),
                    VolonterId = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DogadjajVolonter", x => x.DogadjajVolonterId);
                    table.ForeignKey(
                        name: "FK_DogadjajVolonter_Dogadjaj",
                        column: x => x.DogadjajId,
                        principalTable: "Dogadjaj",
                        principalColumn: "DogadjajId");
                    table.ForeignKey(
                        name: "FK_DogadjajVolonter_Volonter",
                        column: x => x.VolonterId,
                        principalTable: "Volonter",
                        principalColumn: "VolonterId");
                });

            migrationBuilder.CreateTable(
                name: "Udomljavanje",
                columns: table => new
                {
                    UdomljavanjeId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ZahtjevZaUdomljavanjeId = table.Column<int>(type: "int", nullable: false),
                    DatumUdomljavanja = table.Column<DateOnly>(type: "date", nullable: false),
                    Napomena = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Udomljavanje", x => x.UdomljavanjeId);
                    table.ForeignKey(
                        name: "FK_Udomljavanje_Zahtjev",
                        column: x => x.ZahtjevZaUdomljavanjeId,
                        principalTable: "ZahtjevZaUdomljavanje",
                        principalColumn: "ZahtjevZaUdomljavanjeId");
                });

            migrationBuilder.CreateIndex(
                name: "IX_AktivnostVolontera_TipAktivnostiId",
                table: "AktivnostVolontera",
                column: "TipAktivnostiId");

            migrationBuilder.CreateIndex(
                name: "IX_AktivnostVolontera_VolonterId",
                table: "AktivnostVolontera",
                column: "VolonterId");

            migrationBuilder.CreateIndex(
                name: "IX_DogadjajVolonter_VolonterId",
                table: "DogadjajVolonter",
                column: "VolonterId");

            migrationBuilder.CreateIndex(
                name: "UQ_DogadjajVolonter",
                table: "DogadjajVolonter",
                columns: new[] { "DogadjajId", "VolonterId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Donacija_KorisnikId",
                table: "Donacija",
                column: "KorisnikId");

            migrationBuilder.CreateIndex(
                name: "IX_Donacija_StatusDonacijeId",
                table: "Donacija",
                column: "StatusDonacijeId");

            migrationBuilder.CreateIndex(
                name: "IX_Donacija_TipDonacijeId",
                table: "Donacija",
                column: "TipDonacijeId");

            migrationBuilder.CreateIndex(
                name: "IX_Korisnik_GradId",
                table: "Korisnik",
                column: "GradId");

            migrationBuilder.CreateIndex(
                name: "UQ_Korisnik_Email",
                table: "Korisnik",
                column: "Email",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "UQ_Korisnik_KorisnickoIme",
                table: "Korisnik",
                column: "KorisnickoIme",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_KorisnikUloga_UlogaId",
                table: "KorisnikUloga",
                column: "UlogaId");

            migrationBuilder.CreateIndex(
                name: "UQ_KorisnikUloga",
                table: "KorisnikUloga",
                columns: new[] { "KorisnikId", "UlogaId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Obavijest_AutorId",
                table: "Obavijest",
                column: "AutorId");

            migrationBuilder.CreateIndex(
                name: "IX_Pas_RasaId",
                table: "Pas",
                column: "RasaId");

            migrationBuilder.CreateIndex(
                name: "IX_Pas_StatusPsaId",
                table: "Pas",
                column: "StatusPsaId");

            migrationBuilder.CreateIndex(
                name: "IX_Pas_VelicinaPsaId",
                table: "Pas",
                column: "VelicinaPsaId");

            migrationBuilder.CreateIndex(
                name: "IX_Posjeta_KorisnikId",
                table: "Posjeta",
                column: "KorisnikId");

            migrationBuilder.CreateIndex(
                name: "IX_Posjeta_StatusPosjeteId",
                table: "Posjeta",
                column: "StatusPosjeteId");

            migrationBuilder.CreateIndex(
                name: "IX_PregledPsa_KorisnikId",
                table: "PregledPsa",
                column: "KorisnikId");

            migrationBuilder.CreateIndex(
                name: "IX_PregledPsa_PasId",
                table: "PregledPsa",
                column: "PasId");

            migrationBuilder.CreateIndex(
                name: "UQ_Rasa",
                table: "Rasa",
                column: "Naziv",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_SlikaPsa_PasId",
                table: "SlikaPsa",
                column: "PasId");

            migrationBuilder.CreateIndex(
                name: "UQ_StatusDonacije",
                table: "StatusDonacije",
                column: "Naziv",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "UQ_StatusPosjete",
                table: "StatusPosjete",
                column: "Naziv",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "UQ_StatusPsa",
                table: "StatusPsa",
                column: "Naziv",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "UQ_StatusZahtjeva",
                table: "StatusZahtjeva",
                column: "Naziv",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "UQ_TipAktivnosti",
                table: "TipAktivnosti",
                column: "Naziv",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "UQ_TipDonacije",
                table: "TipDonacije",
                column: "Naziv",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "UQ_Udomljavanje",
                table: "Udomljavanje",
                column: "ZahtjevZaUdomljavanjeId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "UQ_Uloga_Naziv",
                table: "Uloga",
                column: "Naziv",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "UQ_VelicinaPsa",
                table: "VelicinaPsa",
                column: "Naziv",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "UQ_Volonter",
                table: "Volonter",
                column: "KorisnikId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_ZahtjevZaUdomljavanje_KorisnikId",
                table: "ZahtjevZaUdomljavanje",
                column: "KorisnikId");

            migrationBuilder.CreateIndex(
                name: "IX_ZahtjevZaUdomljavanje_ObradioKorisnikId",
                table: "ZahtjevZaUdomljavanje",
                column: "ObradioKorisnikId");

            migrationBuilder.CreateIndex(
                name: "IX_ZahtjevZaUdomljavanje_PasId",
                table: "ZahtjevZaUdomljavanje",
                column: "PasId");

            migrationBuilder.CreateIndex(
                name: "IX_ZahtjevZaUdomljavanje_StatusZahtjevaId",
                table: "ZahtjevZaUdomljavanje",
                column: "StatusZahtjevaId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "AktivnostVolontera");

            migrationBuilder.DropTable(
                name: "DogadjajVolonter");

            migrationBuilder.DropTable(
                name: "Donacija");

            migrationBuilder.DropTable(
                name: "KorisnikUloga");

            migrationBuilder.DropTable(
                name: "Obavijest");

            migrationBuilder.DropTable(
                name: "Posjeta");

            migrationBuilder.DropTable(
                name: "PregledPsa");

            migrationBuilder.DropTable(
                name: "SlikaPsa");

            migrationBuilder.DropTable(
                name: "Udomljavanje");

            migrationBuilder.DropTable(
                name: "TipAktivnosti");

            migrationBuilder.DropTable(
                name: "Dogadjaj");

            migrationBuilder.DropTable(
                name: "Volonter");

            migrationBuilder.DropTable(
                name: "StatusDonacije");

            migrationBuilder.DropTable(
                name: "TipDonacije");

            migrationBuilder.DropTable(
                name: "Uloga");

            migrationBuilder.DropTable(
                name: "StatusPosjete");

            migrationBuilder.DropTable(
                name: "ZahtjevZaUdomljavanje");

            migrationBuilder.DropTable(
                name: "Korisnik");

            migrationBuilder.DropTable(
                name: "Pas");

            migrationBuilder.DropTable(
                name: "StatusZahtjeva");

            migrationBuilder.DropTable(
                name: "Grad");

            migrationBuilder.DropTable(
                name: "Rasa");

            migrationBuilder.DropTable(
                name: "StatusPsa");

            migrationBuilder.DropTable(
                name: "VelicinaPsa");
        }
    }
}
