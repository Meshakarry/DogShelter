using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace DogShelter.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddDonacijaPaymentDetails : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "DatumObrade",
                table: "Donacija",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ObradioKorisnikId",
                table: "Donacija",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "RazlogOdbijanja",
                table: "Donacija",
                type: "nvarchar(1000)",
                maxLength: 1000,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "RazlogVracanja",
                table: "Donacija",
                type: "nvarchar(1000)",
                maxLength: 1000,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "StripeRefundId",
                table: "Donacija",
                type: "nvarchar(200)",
                maxLength: 200,
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Donacija_ObradioKorisnikId",
                table: "Donacija",
                column: "ObradioKorisnikId");

            migrationBuilder.AddForeignKey(
                name: "FK_Donacija_ObradioKorisnik",
                table: "Donacija",
                column: "ObradioKorisnikId",
                principalTable: "Korisnik",
                principalColumn: "KorisnikId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Donacija_ObradioKorisnik",
                table: "Donacija");

            migrationBuilder.DropIndex(
                name: "IX_Donacija_ObradioKorisnikId",
                table: "Donacija");

            migrationBuilder.DropColumn(
                name: "DatumObrade",
                table: "Donacija");

            migrationBuilder.DropColumn(
                name: "ObradioKorisnikId",
                table: "Donacija");

            migrationBuilder.DropColumn(
                name: "RazlogOdbijanja",
                table: "Donacija");

            migrationBuilder.DropColumn(
                name: "RazlogVracanja",
                table: "Donacija");

            migrationBuilder.DropColumn(
                name: "StripeRefundId",
                table: "Donacija");
        }
    }
}
