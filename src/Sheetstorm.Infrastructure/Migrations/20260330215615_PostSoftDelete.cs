using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Sheetstorm.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class PostSoftDelete : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Posts_BandId_IsPinned_CreatedAt",
                table: "Posts");

            migrationBuilder.AddColumn<DateTime>(
                name: "DeletedAt",
                table: "Posts",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsDeleted",
                table: "Posts",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.CreateIndex(
                name: "IX_Posts_BandId_IsDeleted_IsPinned_CreatedAt",
                table: "Posts",
                columns: new[] { "BandId", "IsDeleted", "IsPinned", "CreatedAt" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Posts_BandId_IsDeleted_IsPinned_CreatedAt",
                table: "Posts");

            migrationBuilder.DropColumn(
                name: "DeletedAt",
                table: "Posts");

            migrationBuilder.DropColumn(
                name: "IsDeleted",
                table: "Posts");

            migrationBuilder.CreateIndex(
                name: "IX_Posts_BandId_IsPinned_CreatedAt",
                table: "Posts",
                columns: new[] { "BandId", "IsPinned", "CreatedAt" });
        }
    }
}
