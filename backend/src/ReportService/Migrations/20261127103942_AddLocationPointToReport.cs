using Microsoft.EntityFrameworkCore.Migrations;
using NetTopologySuite.Geometries;

#nullable disable

namespace ReportService.Migrations
{
    /// <inheritdoc />
    public partial class AddLocationPointToReport : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterDatabase()
                .Annotation("Npgsql:PostgresExtension:postgis", ",,");

            // Önce boş bırakılabilir eklenir, mevcut ihbarlar enlem/boylamdan doldurulur, sonra zorunlu yapılır
            migrationBuilder.AddColumn<Point>(
                name: "Location",
                table: "Reports",
                type: "geography (point, 4326)",
                nullable: true);

            migrationBuilder.Sql(
                """
                UPDATE "Reports"
                SET "Location" = ST_SetSRID(ST_MakePoint("Longitude", "Latitude"), 4326)::geography;
                """);

            migrationBuilder.AlterColumn<Point>(
                name: "Location",
                table: "Reports",
                type: "geography (point, 4326)",
                nullable: false,
                oldClrType: typeof(Point),
                oldType: "geography (point, 4326)",
                oldNullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Reports_Location",
                table: "Reports",
                column: "Location")
                .Annotation("Npgsql:IndexMethod", "gist");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Reports_Location",
                table: "Reports");

            migrationBuilder.DropColumn(
                name: "Location",
                table: "Reports");

            // PostGIS eklentisi bırakılır: kaldırmak süper kullanıcı yetkisi ister
        }
    }
}
