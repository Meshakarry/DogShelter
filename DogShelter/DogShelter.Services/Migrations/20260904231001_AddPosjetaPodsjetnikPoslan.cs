using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace DogShelter.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddPosjetaPodsjetnikPoslan : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "PodsjetnikPoslan",
                table: "Posjeta",
                type: "bit",
                nullable: false,
                defaultValue: false)
                .Annotation("Relational:DefaultConstraintName", "DF_Posjeta_PodsjetnikPoslan");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "PodsjetnikPoslan",
                table: "Posjeta")
                .Annotation("Relational:DefaultConstraintName", "DF_Posjeta_PodsjetnikPoslan");
        }
    }
}
