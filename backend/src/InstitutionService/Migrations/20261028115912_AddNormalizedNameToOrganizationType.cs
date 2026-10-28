using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace InstitutionService.Migrations
{
    /// <inheritdoc />
    public partial class AddNormalizedNameToOrganizationType : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<string>(
                name: "Name",
                table: "OrganizationTypes",
                type: "character varying(100)",
                maxLength: 100,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "text");

            migrationBuilder.AddColumn<string>(
                name: "NormalizedName",
                table: "OrganizationTypes",
                type: "character varying(100)",
                maxLength: 100,
                nullable: true);

            migrationBuilder.Sql(
                """
                UPDATE "OrganizationTypes"
                SET "NormalizedName" = upper(
                    translate(trim("Name"), 'iı', 'İI')
                );
                """);

            migrationBuilder.AlterColumn<string>(
                name: "NormalizedName",
                table: "OrganizationTypes",
                type: "character varying(100)",
                maxLength: 100,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "character varying(100)",
                oldMaxLength: 100,
                oldNullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_OrganizationTypes_NormalizedName",
                table: "OrganizationTypes",
                column: "NormalizedName",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_OrganizationTypes_NormalizedName",
                table: "OrganizationTypes");

            migrationBuilder.DropColumn(
                name: "NormalizedName",
                table: "OrganizationTypes");

            migrationBuilder.AlterColumn<string>(
                name: "Name",
                table: "OrganizationTypes",
                type: "text",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "character varying(100)",
                oldMaxLength: 100);
        }
    }
}
