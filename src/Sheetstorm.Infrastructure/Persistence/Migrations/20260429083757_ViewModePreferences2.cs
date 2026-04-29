using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Sheetstorm.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class ViewModePreferences2 : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "DefaultViewMode",
                table: "Pieces",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "ViewMode",
                table: "Parts",
                type: "integer",
                nullable: false,
                defaultValue: 0);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "DefaultViewMode",
                table: "Pieces");

            migrationBuilder.DropColumn(
                name: "ViewMode",
                table: "Parts");
        }
    }
}
