using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Sheetstorm.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddSyncSessionPublicKey : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<long>(
                name: "CurrentCounter",
                table: "EventSyncSessions",
                type: "bigint",
                nullable: false,
                defaultValue: 0L);

            migrationBuilder.AddColumn<string>(
                name: "PublicKeyBase64",
                table: "EventSyncSessions",
                type: "text",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "CurrentCounter",
                table: "EventSyncSessions");

            migrationBuilder.DropColumn(
                name: "PublicKeyBase64",
                table: "EventSyncSessions");
        }
    }
}
