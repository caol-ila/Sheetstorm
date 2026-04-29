using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Sheetstorm.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddPieces : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Pieces",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    BandId = table.Column<Guid>(type: "uuid", nullable: false),
                    Title = table.Column<string>(type: "character varying(300)", maxLength: 300, nullable: false),
                    Subtitle = table.Column<string>(type: "character varying(300)", maxLength: 300, nullable: true),
                    Composer = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    Arranger = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    Publisher = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    PublisherNumber = table.Column<string>(type: "character varying(80)", maxLength: 80, nullable: true),
                    KeySignature = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: true),
                    TimeSignature = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: true),
                    Tempo = table.Column<int>(type: "integer", nullable: true),
                    DurationSeconds = table.Column<int>(type: "integer", nullable: true),
                    Difficulty = table.Column<int>(type: "integer", nullable: true),
                    Genre = table.Column<string>(type: "character varying(80)", maxLength: 80, nullable: true),
                    Tags = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    Notes = table.Column<string>(type: "text", nullable: true),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    DeletedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Pieces", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Parts",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    PieceId = table.Column<Guid>(type: "uuid", nullable: false),
                    InstrumentId = table.Column<Guid>(type: "uuid", nullable: false),
                    Transposition = table.Column<string>(type: "character varying(8)", maxLength: 8, nullable: true),
                    Register = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: true),
                    DisplayName = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    OrderHint = table.Column<int>(type: "integer", nullable: false),
                    Retired = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Parts", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Parts_Instruments_InstrumentId",
                        column: x => x.InstrumentId,
                        principalTable: "Instruments",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Parts_Pieces_PieceId",
                        column: x => x.PieceId,
                        principalTable: "Pieces",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "PartFiles",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    PartId = table.Column<Guid>(type: "uuid", nullable: false),
                    Kind = table.Column<int>(type: "integer", nullable: false),
                    BlobKey = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    OriginalFileName = table.Column<string>(type: "character varying(300)", maxLength: 300, nullable: false),
                    Pages = table.Column<int>(type: "integer", nullable: true),
                    SizeBytes = table.Column<long>(type: "bigint", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PartFiles", x => x.Id);
                    table.ForeignKey(
                        name: "FK_PartFiles_Parts_PartId",
                        column: x => x.PartId,
                        principalTable: "Parts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_PartFiles_PartId",
                table: "PartFiles",
                column: "PartId");

            migrationBuilder.CreateIndex(
                name: "IX_Parts_InstrumentId",
                table: "Parts",
                column: "InstrumentId");

            migrationBuilder.CreateIndex(
                name: "IX_Parts_PieceId",
                table: "Parts",
                column: "PieceId");

            migrationBuilder.CreateIndex(
                name: "IX_Pieces_BandId",
                table: "Pieces",
                column: "BandId");

            migrationBuilder.CreateIndex(
                name: "IX_Pieces_BandId_Title",
                table: "Pieces",
                columns: new[] { "BandId", "Title" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "PartFiles");

            migrationBuilder.DropTable(
                name: "Parts");

            migrationBuilder.DropTable(
                name: "Pieces");
        }
    }
}
