using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace DogShelter.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddRecommenderSignals : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "NivoAktivnostiId",
                table: "Pas",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateTable(
                name: "Favorit",
                columns: table => new
                {
                    FavoritId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    KorisnikId = table.Column<int>(type: "int", nullable: false),
                    PasId = table.Column<int>(type: "int", nullable: false),
                    DatumDodavanja = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "(sysdatetime())")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Favorit", x => x.FavoritId);
                    table.ForeignKey(
                        name: "FK_Favorit_Korisnik",
                        column: x => x.KorisnikId,
                        principalTable: "Korisnik",
                        principalColumn: "KorisnikId");
                    table.ForeignKey(
                        name: "FK_Favorit_Pas",
                        column: x => x.PasId,
                        principalTable: "Pas",
                        principalColumn: "PasId");
                });

            migrationBuilder.CreateTable(
                name: "NivoAktivnosti",
                columns: table => new
                {
                    NivoAktivnostiId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Naziv = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_NivoAktivnosti", x => x.NivoAktivnostiId);
                });

            migrationBuilder.CreateTable(
                name: "PretragaLog",
                columns: table => new
                {
                    PretragaLogId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    KorisnikId = table.Column<int>(type: "int", nullable: false),
                    RasaId = table.Column<int>(type: "int", nullable: true),
                    VelicinaPsaId = table.Column<int>(type: "int", nullable: true),
                    Spol = table.Column<int>(type: "int", nullable: true),
                    NivoAktivnostiId = table.Column<int>(type: "int", nullable: true),
                    DatumPretrage = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "(sysdatetime())")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PretragaLog", x => x.PretragaLogId);
                    table.ForeignKey(
                        name: "FK_PretragaLog_Korisnik",
                        column: x => x.KorisnikId,
                        principalTable: "Korisnik",
                        principalColumn: "KorisnikId");
                    table.ForeignKey(
                        name: "FK_PretragaLog_NivoAktivnosti",
                        column: x => x.NivoAktivnostiId,
                        principalTable: "NivoAktivnosti",
                        principalColumn: "NivoAktivnostiId");
                    table.ForeignKey(
                        name: "FK_PretragaLog_Rasa",
                        column: x => x.RasaId,
                        principalTable: "Rasa",
                        principalColumn: "RasaId");
                    table.ForeignKey(
                        name: "FK_PretragaLog_Velicina",
                        column: x => x.VelicinaPsaId,
                        principalTable: "VelicinaPsa",
                        principalColumn: "VelicinaPsaId");
                });

            migrationBuilder.CreateIndex(
                name: "IX_Pas_NivoAktivnostiId",
                table: "Pas",
                column: "NivoAktivnostiId");

            migrationBuilder.CreateIndex(
                name: "IX_Favorit_PasId",
                table: "Favorit",
                column: "PasId");

            migrationBuilder.CreateIndex(
                name: "UQ_Favorit_Korisnik_Pas",
                table: "Favorit",
                columns: new[] { "KorisnikId", "PasId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "UQ_NivoAktivnosti",
                table: "NivoAktivnosti",
                column: "Naziv",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_PretragaLog_KorisnikId",
                table: "PretragaLog",
                column: "KorisnikId");

            migrationBuilder.CreateIndex(
                name: "IX_PretragaLog_NivoAktivnostiId",
                table: "PretragaLog",
                column: "NivoAktivnostiId");

            migrationBuilder.CreateIndex(
                name: "IX_PretragaLog_RasaId",
                table: "PretragaLog",
                column: "RasaId");

            migrationBuilder.CreateIndex(
                name: "IX_PretragaLog_VelicinaPsaId",
                table: "PretragaLog",
                column: "VelicinaPsaId");

            // Seed the lookup here (not left to DatabaseSeeder, which only runs once the app
            // starts) so the FK added below has a real row to point every existing Pas at -
            // DatabaseSeeder's own EnsureNivoAktivnostiAsync no-ops on these via its AnyAsync
            // check next time the app boots.
            migrationBuilder.Sql("INSERT INTO NivoAktivnosti (Naziv) VALUES (N'Nizak'), (N'Srednji'), (N'Visok');");
            migrationBuilder.Sql("UPDATE Pas SET NivoAktivnostiId = (SELECT NivoAktivnostiId FROM NivoAktivnosti WHERE Naziv = N'Srednji') WHERE NivoAktivnostiId = 0;");

            migrationBuilder.AddForeignKey(
                name: "FK_Pas_NivoAktivnosti",
                table: "Pas",
                column: "NivoAktivnostiId",
                principalTable: "NivoAktivnosti",
                principalColumn: "NivoAktivnostiId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Pas_NivoAktivnosti",
                table: "Pas");

            migrationBuilder.DropTable(
                name: "Favorit");

            migrationBuilder.DropTable(
                name: "PretragaLog");

            migrationBuilder.DropTable(
                name: "NivoAktivnosti");

            migrationBuilder.DropIndex(
                name: "IX_Pas_NivoAktivnostiId",
                table: "Pas");

            migrationBuilder.DropColumn(
                name: "NivoAktivnostiId",
                table: "Pas");
        }
    }
}
