using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace DogShelter.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddDonacijaStavka : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Donacija_JedinicaMjere",
                table: "Donacija");

            migrationBuilder.DropForeignKey(
                name: "FK_Donacija_Kategorija",
                table: "Donacija");

            migrationBuilder.DropIndex(
                name: "IX_Donacija_JedinicaMjereId",
                table: "Donacija");

            migrationBuilder.DropIndex(
                name: "IX_Donacija_KategorijaDonacijeId",
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

            migrationBuilder.CreateTable(
                name: "DonacijaStavka",
                columns: table => new
                {
                    DonacijaStavkaId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    DonacijaId = table.Column<int>(type: "int", nullable: false),
                    KategorijaDonacijeId = table.Column<int>(type: "int", nullable: false),
                    PrilagodjenNaziv = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: true),
                    Kolicina = table.Column<decimal>(type: "decimal(10,2)", nullable: false),
                    JedinicaMjereId = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DonacijaStavka", x => x.DonacijaStavkaId);
                    table.ForeignKey(
                        name: "FK_DonacijaStavka_Donacija",
                        column: x => x.DonacijaId,
                        principalTable: "Donacija",
                        principalColumn: "DonacijaId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_DonacijaStavka_JedinicaMjere",
                        column: x => x.JedinicaMjereId,
                        principalTable: "JedinicaMjere",
                        principalColumn: "JedinicaMjereId");
                    table.ForeignKey(
                        name: "FK_DonacijaStavka_Kategorija",
                        column: x => x.KategorijaDonacijeId,
                        principalTable: "KategorijaDonacije",
                        principalColumn: "KategorijaDonacijeId");
                });

            migrationBuilder.CreateIndex(
                name: "IX_DonacijaStavka_DonacijaId",
                table: "DonacijaStavka",
                column: "DonacijaId");

            migrationBuilder.CreateIndex(
                name: "IX_DonacijaStavka_JedinicaMjereId",
                table: "DonacijaStavka",
                column: "JedinicaMjereId");

            migrationBuilder.CreateIndex(
                name: "IX_DonacijaStavka_KategorijaDonacijeId",
                table: "DonacijaStavka",
                column: "KategorijaDonacijeId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "DonacijaStavka");

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

            migrationBuilder.CreateIndex(
                name: "IX_Donacija_JedinicaMjereId",
                table: "Donacija",
                column: "JedinicaMjereId");

            migrationBuilder.CreateIndex(
                name: "IX_Donacija_KategorijaDonacijeId",
                table: "Donacija",
                column: "KategorijaDonacijeId");

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
    }
}
