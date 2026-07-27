using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace DogShelter.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddMaterijalnaDonacijaAndPotrebeAzila : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "AdresaPreuzimanja",
                table: "Donacija",
                type: "nvarchar(255)",
                maxLength: 255,
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "DatumPreuzimanja",
                table: "Donacija",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "JedinicaMjereId",
                table: "Donacija",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "KategorijaDonacijeId",
                table: "Donacija",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "Kolicina",
                table: "Donacija",
                type: "decimal(10,2)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "PrilagodjenNaziv",
                table: "Donacija",
                type: "nvarchar(200)",
                maxLength: 200,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "TelefonPreuzimanja",
                table: "Donacija",
                type: "nvarchar(30)",
                maxLength: 30,
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "TrebaPreuzimanje",
                table: "Donacija",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTime>(
                name: "ZeljeniDatumDostave",
                table: "Donacija",
                type: "datetime2",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "JedinicaMjere",
                columns: table => new
                {
                    JedinicaMjereId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Naziv = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_JedinicaMjere", x => x.JedinicaMjereId);
                });

            migrationBuilder.CreateTable(
                name: "KategorijaDonacije",
                columns: table => new
                {
                    KategorijaDonacijeId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Naziv = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    IkonaKljuc = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_KategorijaDonacije", x => x.KategorijaDonacijeId);
                });

            migrationBuilder.CreateTable(
                name: "PrioritetPotrebe",
                columns: table => new
                {
                    PrioritetPotrebeId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Naziv = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PrioritetPotrebe", x => x.PrioritetPotrebeId);
                });

            migrationBuilder.CreateTable(
                name: "PotrebaAzila",
                columns: table => new
                {
                    PotrebaAzilaId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Naziv = table.Column<string>(type: "nvarchar(150)", maxLength: 150, nullable: false),
                    Opis = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    PrioritetPotrebeId = table.Column<int>(type: "int", nullable: false),
                    IkonaKljuc = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Aktivna = table.Column<bool>(type: "bit", nullable: false, defaultValue: true),
                    DatumKreiranja = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "(sysdatetime())")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PotrebaAzila", x => x.PotrebaAzilaId);
                    table.ForeignKey(
                        name: "FK_PotrebaAzila_Prioritet",
                        column: x => x.PrioritetPotrebeId,
                        principalTable: "PrioritetPotrebe",
                        principalColumn: "PrioritetPotrebeId");
                });

            migrationBuilder.CreateIndex(
                name: "IX_Donacija_JedinicaMjereId",
                table: "Donacija",
                column: "JedinicaMjereId");

            migrationBuilder.CreateIndex(
                name: "IX_Donacija_KategorijaDonacijeId",
                table: "Donacija",
                column: "KategorijaDonacijeId");

            migrationBuilder.CreateIndex(
                name: "UQ_JedinicaMjere",
                table: "JedinicaMjere",
                column: "Naziv",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "UQ_KategorijaDonacije",
                table: "KategorijaDonacije",
                column: "Naziv",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_PotrebaAzila_PrioritetPotrebeId",
                table: "PotrebaAzila",
                column: "PrioritetPotrebeId");

            migrationBuilder.CreateIndex(
                name: "UQ_PrioritetPotrebe",
                table: "PrioritetPotrebe",
                column: "Naziv",
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_Donacija_JedinicaMjere",
                table: "Donacija",
                column: "JedinicaMjereId",
                principalTable: "JedinicaMjere",
                principalColumn: "JedinicaMjereId");

            migrationBuilder.AddForeignKey(
                name: "FK_Donacija_Kategorija",
                table: "Donacija",
                column: "KategorijaDonacijeId",
                principalTable: "KategorijaDonacije",
                principalColumn: "KategorijaDonacijeId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Donacija_JedinicaMjere",
                table: "Donacija");

            migrationBuilder.DropForeignKey(
                name: "FK_Donacija_Kategorija",
                table: "Donacija");

            migrationBuilder.DropTable(
                name: "JedinicaMjere");

            migrationBuilder.DropTable(
                name: "KategorijaDonacije");

            migrationBuilder.DropTable(
                name: "PotrebaAzila");

            migrationBuilder.DropTable(
                name: "PrioritetPotrebe");

            migrationBuilder.DropIndex(
                name: "IX_Donacija_JedinicaMjereId",
                table: "Donacija");

            migrationBuilder.DropIndex(
                name: "IX_Donacija_KategorijaDonacijeId",
                table: "Donacija");

            migrationBuilder.DropColumn(
                name: "AdresaPreuzimanja",
                table: "Donacija");

            migrationBuilder.DropColumn(
                name: "DatumPreuzimanja",
                table: "Donacija");

            migrationBuilder.DropColumn(
                name: "JedinicaMjereId",
                table: "Donacija");

            migrationBuilder.DropColumn(
                name: "KategorijaDonacijeId",
                table: "Donacija");

            migrationBuilder.DropColumn(
                name: "Kolicina",
                table: "Donacija");

            migrationBuilder.DropColumn(
                name: "PrilagodjenNaziv",
                table: "Donacija");

            migrationBuilder.DropColumn(
                name: "TelefonPreuzimanja",
                table: "Donacija");

            migrationBuilder.DropColumn(
                name: "TrebaPreuzimanje",
                table: "Donacija");

            migrationBuilder.DropColumn(
                name: "ZeljeniDatumDostave",
                table: "Donacija");
        }
    }
}
