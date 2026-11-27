using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ReportService.Migrations
{
    /// <inheritdoc />
    public partial class AddAnswersToReport : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Answers",
                table: "Reports",
                type: "jsonb",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Answers",
                table: "Reports");
        }
    }
}
