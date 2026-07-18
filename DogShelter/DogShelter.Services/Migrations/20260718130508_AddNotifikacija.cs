using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace DogShelter.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddNotifikacija : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Notifikacija",
                columns: table => new
                {
                    NotifikacijaId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    KorisnikId = table.Column<int>(type: "int", nullable: false),
                    Tip = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Naslov = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    Tekst = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: false),
                    VezaniEntitetId = table.Column<int>(type: "int", nullable: true),
                    Procitano = table.Column<bool>(type: "bit", nullable: false, defaultValue: false),
                    DatumKreiranja = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "(sysdatetime())")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Notifikacija", x => x.NotifikacijaId);
                    table.ForeignKey(
                        name: "FK_Notifikacija_Korisnik",
                        column: x => x.KorisnikId,
                        principalTable: "Korisnik",
                        principalColumn: "KorisnikId");
                });

            migrationBuilder.CreateIndex(
                name: "IX_Notifikacija_Korisnik_Procitano",
                table: "Notifikacija",
                columns: new[] { "KorisnikId", "Procitano" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Notifikacija");
        }
    }
}
