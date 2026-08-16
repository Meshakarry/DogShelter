using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace DogShelter.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddPosjetaDatumVrijemeIndex : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateIndex(
                name: "IX_Posjeta_DatumVrijeme",
                table: "Posjeta",
                column: "DatumVrijeme");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Posjeta_DatumVrijeme",
                table: "Posjeta");
        }
    }
}
