using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace DogShelter.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddLozinkaResetToken : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "LozinkaResetToken",
                columns: table => new
                {
                    LozinkaResetTokenId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    KorisnikId = table.Column<int>(type: "int", nullable: false),
                    KodHash = table.Column<string>(type: "nvarchar(128)", maxLength: 128, nullable: false),
                    DatumKreiranja = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "(sysdatetime())"),
                    IsticeU = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Iskoristen = table.Column<bool>(type: "bit", nullable: false, defaultValue: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LozinkaResetToken", x => x.LozinkaResetTokenId);
                    table.ForeignKey(
                        name: "FK_LozinkaResetToken_Korisnik",
                        column: x => x.KorisnikId,
                        principalTable: "Korisnik",
                        principalColumn: "KorisnikId");
                });

            migrationBuilder.CreateIndex(
                name: "IX_LozinkaResetToken_KorisnikId",
                table: "LozinkaResetToken",
                column: "KorisnikId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "LozinkaResetToken");
        }
    }
}
