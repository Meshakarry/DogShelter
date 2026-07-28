using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace DogShelter.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddKategorijaDonacijeJedinicaMjereMapping : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "PodrazumijevanaJedinicaMjereId",
                table: "KategorijaDonacije",
                type: "int",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "KategorijaDonacijeJedinicaMjere",
                columns: table => new
                {
                    DozvoljeneJediniceJedinicaMjereId = table.Column<int>(type: "int", nullable: false),
                    KategorijaDonacijeId = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_KategorijaDonacijeJedinicaMjere", x => new { x.DozvoljeneJediniceJedinicaMjereId, x.KategorijaDonacijeId });
                    table.ForeignKey(
                        name: "FK_KategorijaDonacijeJedinicaMjere_JedinicaMjere_DozvoljeneJediniceJedinicaMjereId",
                        column: x => x.DozvoljeneJediniceJedinicaMjereId,
                        principalTable: "JedinicaMjere",
                        principalColumn: "JedinicaMjereId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_KategorijaDonacijeJedinicaMjere_KategorijaDonacije_KategorijaDonacijeId",
                        column: x => x.KategorijaDonacijeId,
                        principalTable: "KategorijaDonacije",
                        principalColumn: "KategorijaDonacijeId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_KategorijaDonacije_PodrazumijevanaJedinicaMjereId",
                table: "KategorijaDonacije",
                column: "PodrazumijevanaJedinicaMjereId");

            migrationBuilder.CreateIndex(
                name: "IX_KategorijaDonacijeJedinicaMjere_KategorijaDonacijeId",
                table: "KategorijaDonacijeJedinicaMjere",
                column: "KategorijaDonacijeId");

            migrationBuilder.AddForeignKey(
                name: "FK_KategorijaDonacije_PodrazumijevanaJedinica",
                table: "KategorijaDonacije",
                column: "PodrazumijevanaJedinicaMjereId",
                principalTable: "JedinicaMjere",
                principalColumn: "JedinicaMjereId",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_KategorijaDonacije_PodrazumijevanaJedinica",
                table: "KategorijaDonacije");

            migrationBuilder.DropTable(
                name: "KategorijaDonacijeJedinicaMjere");

            migrationBuilder.DropIndex(
                name: "IX_KategorijaDonacije_PodrazumijevanaJedinicaMjereId",
                table: "KategorijaDonacije");

            migrationBuilder.DropColumn(
                name: "PodrazumijevanaJedinicaMjereId",
                table: "KategorijaDonacije");
        }
    }
}
