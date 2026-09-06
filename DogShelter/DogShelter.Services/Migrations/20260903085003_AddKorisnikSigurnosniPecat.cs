using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace DogShelter.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddKorisnikSigurnosniPecat : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "SigurnosniPecat",
                table: "Korisnik",
                type: "uniqueidentifier",
                nullable: false,
                defaultValueSql: "(newid())")
                .Annotation("Relational:DefaultConstraintName", "DF_Korisnik_SigurnosniPecat");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "SigurnosniPecat",
                table: "Korisnik")
                .Annotation("Relational:DefaultConstraintName", "DF_Korisnik_SigurnosniPecat");
        }
    }
}
