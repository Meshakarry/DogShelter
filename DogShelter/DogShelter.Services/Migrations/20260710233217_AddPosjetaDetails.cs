using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace DogShelter.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddPosjetaDetails : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "DatumKreiranja",
                table: "Posjeta",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<DateTime>(
                name: "DatumObrade",
                table: "Posjeta",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ObradioKorisnikId",
                table: "Posjeta",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "PasId",
                table: "Posjeta",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "RazlogOtkazivanja",
                table: "Posjeta",
                type: "nvarchar(1000)",
                maxLength: 1000,
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Posjeta_ObradioKorisnikId",
                table: "Posjeta",
                column: "ObradioKorisnikId");

            migrationBuilder.CreateIndex(
                name: "IX_Posjeta_PasId",
                table: "Posjeta",
                column: "PasId");

            migrationBuilder.AddForeignKey(
                name: "FK_Posjeta_ObradioKorisnik",
                table: "Posjeta",
                column: "ObradioKorisnikId",
                principalTable: "Korisnik",
                principalColumn: "KorisnikId");

            migrationBuilder.AddForeignKey(
                name: "FK_Posjeta_Pas",
                table: "Posjeta",
                column: "PasId",
                principalTable: "Pas",
                principalColumn: "PasId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Posjeta_ObradioKorisnik",
                table: "Posjeta");

            migrationBuilder.DropForeignKey(
                name: "FK_Posjeta_Pas",
                table: "Posjeta");

            migrationBuilder.DropIndex(
                name: "IX_Posjeta_ObradioKorisnikId",
                table: "Posjeta");

            migrationBuilder.DropIndex(
                name: "IX_Posjeta_PasId",
                table: "Posjeta");

            migrationBuilder.DropColumn(
                name: "DatumKreiranja",
                table: "Posjeta");

            migrationBuilder.DropColumn(
                name: "DatumObrade",
                table: "Posjeta");

            migrationBuilder.DropColumn(
                name: "ObradioKorisnikId",
                table: "Posjeta");

            migrationBuilder.DropColumn(
                name: "PasId",
                table: "Posjeta");

            migrationBuilder.DropColumn(
                name: "RazlogOtkazivanja",
                table: "Posjeta");
        }
    }
}
