using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Sheetstorm.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddStueckImportEntities : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Kapellen",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "character varying(80)", maxLength: 80, nullable: false),
                    Beschreibung = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    Ort = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    LogoUrl = table.Column<string>(type: "character varying(512)", maxLength: 512, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Kapellen", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Musiker",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    Email = table.Column<string>(type: "character varying(256)", maxLength: 256, nullable: false),
                    PasswordHash = table.Column<string>(type: "text", nullable: false),
                    Instrument = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    OnboardingCompleted = table.Column<bool>(type: "boolean", nullable: false),
                    EmailVerified = table.Column<bool>(type: "boolean", nullable: false),
                    EmailVerificationToken = table.Column<string>(type: "text", nullable: true),
                    EmailVerificationTokenExpiresAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    PasswordResetToken = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: true),
                    PasswordResetTokenExpiresAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    PasswordResetRequestedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Musiker", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "KapelleStimmenMappings",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    KapelleId = table.Column<Guid>(type: "uuid", nullable: false),
                    Instrument = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    Stimme = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_KapelleStimmenMappings", x => x.Id);
                    table.ForeignKey(
                        name: "FK_KapelleStimmenMappings_Kapellen_KapelleId",
                        column: x => x.KapelleId,
                        principalTable: "Kapellen",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Einladungen",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Code = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    KapelleID = table.Column<Guid>(type: "uuid", nullable: false),
                    VorgeseheRolle = table.Column<int>(type: "integer", nullable: false),
                    ExpiresAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsUsed = table.Column<bool>(type: "boolean", nullable: false),
                    ErstelltVonMusikerID = table.Column<Guid>(type: "uuid", nullable: false),
                    EingeloestVonMusikerID = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Einladungen", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Einladungen_Kapellen_KapelleID",
                        column: x => x.KapelleID,
                        principalTable: "Kapellen",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Einladungen_Musiker_EingeloestVonMusikerID",
                        column: x => x.EingeloestVonMusikerID,
                        principalTable: "Musiker",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_Einladungen_Musiker_ErstelltVonMusikerID",
                        column: x => x.ErstelltVonMusikerID,
                        principalTable: "Musiker",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "Mitgliedschaften",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    MusikerID = table.Column<Guid>(type: "uuid", nullable: false),
                    KapelleID = table.Column<Guid>(type: "uuid", nullable: false),
                    Rolle = table.Column<int>(type: "integer", nullable: false),
                    IstAktiv = table.Column<bool>(type: "boolean", nullable: false),
                    StimmenOverride = table.Column<string>(type: "text", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Mitgliedschaften", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Mitgliedschaften_Kapellen_KapelleID",
                        column: x => x.KapelleID,
                        principalTable: "Kapellen",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Mitgliedschaften_Musiker_MusikerID",
                        column: x => x.MusikerID,
                        principalTable: "Musiker",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "RefreshTokens",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Token = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: false),
                    FamilyId = table.Column<Guid>(type: "uuid", nullable: false),
                    IsUsed = table.Column<bool>(type: "boolean", nullable: false),
                    IsRevoked = table.Column<bool>(type: "boolean", nullable: false),
                    ExpiresAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    MusikerId = table.Column<Guid>(type: "uuid", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_RefreshTokens", x => x.Id);
                    table.ForeignKey(
                        name: "FK_RefreshTokens_Musiker_MusikerId",
                        column: x => x.MusikerId,
                        principalTable: "Musiker",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Stuecke",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    KapelleID = table.Column<Guid>(type: "uuid", nullable: true),
                    MusikerID = table.Column<Guid>(type: "uuid", nullable: true),
                    Titel = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Komponist = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    Arrangeur = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    VeroeffentlichungsJahr = table.Column<int>(type: "integer", nullable: true),
                    Tonart = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    Taktart = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    Tempo = table.Column<int>(type: "integer", nullable: true),
                    Beschreibung = table.Column<string>(type: "character varying(2000)", maxLength: 2000, nullable: true),
                    OriginalDateiname = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    StorageKey = table.Column<string>(type: "character varying(1024)", maxLength: 1024, nullable: true),
                    ImportStatus = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Stuecke", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Stuecke_Kapellen_KapelleID",
                        column: x => x.KapelleID,
                        principalTable: "Kapellen",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Stuecke_Musiker_MusikerID",
                        column: x => x.MusikerID,
                        principalTable: "Musiker",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateTable(
                name: "Stimmen",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    StueckID = table.Column<Guid>(type: "uuid", nullable: false),
                    Bezeichnung = table.Column<string>(type: "text", nullable: false),
                    Instrument = table.Column<string>(type: "text", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Stimmen", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Stimmen_Stuecke_StueckID",
                        column: x => x.StueckID,
                        principalTable: "Stuecke",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "StueckSeiten",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    StueckID = table.Column<Guid>(type: "uuid", nullable: false),
                    Seitennummer = table.Column<int>(type: "integer", nullable: false),
                    StorageKey = table.Column<string>(type: "character varying(1024)", maxLength: 1024, nullable: false),
                    OcrText = table.Column<string>(type: "text", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_StueckSeiten", x => x.Id);
                    table.ForeignKey(
                        name: "FK_StueckSeiten_Stuecke_StueckID",
                        column: x => x.StueckID,
                        principalTable: "Stuecke",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Notenblaetter",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    StimmeID = table.Column<Guid>(type: "uuid", nullable: false),
                    BlobUrl = table.Column<string>(type: "text", nullable: false),
                    ContentType = table.Column<string>(type: "text", nullable: true),
                    FileSizeBytes = table.Column<long>(type: "bigint", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Notenblaetter", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Notenblaetter_Stimmen_StimmeID",
                        column: x => x.StimmeID,
                        principalTable: "Stimmen",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Einladungen_Code",
                table: "Einladungen",
                column: "Code",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Einladungen_EingeloestVonMusikerID",
                table: "Einladungen",
                column: "EingeloestVonMusikerID");

            migrationBuilder.CreateIndex(
                name: "IX_Einladungen_ErstelltVonMusikerID",
                table: "Einladungen",
                column: "ErstelltVonMusikerID");

            migrationBuilder.CreateIndex(
                name: "IX_Einladungen_KapelleID",
                table: "Einladungen",
                column: "KapelleID");

            migrationBuilder.CreateIndex(
                name: "IX_KapelleStimmenMappings_KapelleId_Instrument",
                table: "KapelleStimmenMappings",
                columns: new[] { "KapelleId", "Instrument" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Mitgliedschaften_KapelleID",
                table: "Mitgliedschaften",
                column: "KapelleID");

            migrationBuilder.CreateIndex(
                name: "IX_Mitgliedschaften_MusikerID_KapelleID",
                table: "Mitgliedschaften",
                columns: new[] { "MusikerID", "KapelleID" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Musiker_Email",
                table: "Musiker",
                column: "Email",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Musiker_PasswordResetToken",
                table: "Musiker",
                column: "PasswordResetToken",
                unique: true,
                filter: "\"PasswordResetToken\" IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_Notenblaetter_StimmeID",
                table: "Notenblaetter",
                column: "StimmeID");

            migrationBuilder.CreateIndex(
                name: "IX_RefreshTokens_FamilyId",
                table: "RefreshTokens",
                column: "FamilyId");

            migrationBuilder.CreateIndex(
                name: "IX_RefreshTokens_MusikerId",
                table: "RefreshTokens",
                column: "MusikerId");

            migrationBuilder.CreateIndex(
                name: "IX_RefreshTokens_Token",
                table: "RefreshTokens",
                column: "Token",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Stimmen_StueckID",
                table: "Stimmen",
                column: "StueckID");

            migrationBuilder.CreateIndex(
                name: "IX_Stuecke_KapelleID",
                table: "Stuecke",
                column: "KapelleID");

            migrationBuilder.CreateIndex(
                name: "IX_Stuecke_MusikerID",
                table: "Stuecke",
                column: "MusikerID");

            migrationBuilder.CreateIndex(
                name: "IX_StueckSeiten_StueckID_Seitennummer",
                table: "StueckSeiten",
                columns: new[] { "StueckID", "Seitennummer" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Einladungen");

            migrationBuilder.DropTable(
                name: "KapelleStimmenMappings");

            migrationBuilder.DropTable(
                name: "Mitgliedschaften");

            migrationBuilder.DropTable(
                name: "Notenblaetter");

            migrationBuilder.DropTable(
                name: "RefreshTokens");

            migrationBuilder.DropTable(
                name: "StueckSeiten");

            migrationBuilder.DropTable(
                name: "Stimmen");

            migrationBuilder.DropTable(
                name: "Stuecke");

            migrationBuilder.DropTable(
                name: "Kapellen");

            migrationBuilder.DropTable(
                name: "Musiker");
        }
    }
}
