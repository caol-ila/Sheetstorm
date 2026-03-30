using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Sheetstorm.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class MS2_AllFeatures : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_RefreshTokens_Musiker_MusikerId",
                table: "RefreshTokens");

            migrationBuilder.DropTable(
                name: "Einladungen");

            migrationBuilder.DropTable(
                name: "KapelleStimmenMappings");

            migrationBuilder.DropTable(
                name: "Mitgliedschaften");

            migrationBuilder.DropTable(
                name: "Notenblaetter");

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

            migrationBuilder.RenameColumn(
                name: "MusikerId",
                table: "RefreshTokens",
                newName: "MusicianId");

            migrationBuilder.RenameIndex(
                name: "IX_RefreshTokens_MusikerId",
                table: "RefreshTokens",
                newName: "IX_RefreshTokens_MusicianId");

            migrationBuilder.CreateTable(
                name: "Bands",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "character varying(80)", maxLength: 80, nullable: false),
                    Description = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    Location = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    LogoUrl = table.Column<string>(type: "character varying(512)", maxLength: 512, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Bands", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "ConfigAudit",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    BandId = table.Column<Guid>(type: "uuid", nullable: true),
                    MusicianId = table.Column<Guid>(type: "uuid", nullable: true),
                    Level = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    Key = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    OldValue = table.Column<string>(type: "jsonb", nullable: true),
                    NewValue = table.Column<string>(type: "jsonb", nullable: true),
                    Timestamp = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ConfigAudit", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Musicians",
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
                    table.PrimaryKey("PK_Musicians", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "BandVoiceMappings",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    BandId = table.Column<Guid>(type: "uuid", nullable: false),
                    Instrument = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    Voice = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_BandVoiceMappings", x => x.Id);
                    table.ForeignKey(
                        name: "FK_BandVoiceMappings_Bands_BandId",
                        column: x => x.BandId,
                        principalTable: "Bands",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Setlists",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    BandId = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                    Description = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    Type = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false),
                    EventId = table.Column<Guid>(type: "uuid", nullable: true),
                    Date = table.Column<DateOnly>(type: "date", nullable: true),
                    StartTime = table.Column<TimeOnly>(type: "time without time zone", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Setlists", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Setlists_Bands_BandId",
                        column: x => x.BandId,
                        principalTable: "Bands",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "AttendanceRecords",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    BandId = table.Column<Guid>(type: "uuid", nullable: false),
                    EventId = table.Column<Guid>(type: "uuid", nullable: true),
                    MusicianId = table.Column<Guid>(type: "uuid", nullable: false),
                    Date = table.Column<DateOnly>(type: "date", nullable: false),
                    Status = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false),
                    Notes = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    RecordedByMusicianId = table.Column<Guid>(type: "uuid", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AttendanceRecords", x => x.Id);
                    table.ForeignKey(
                        name: "FK_AttendanceRecords_Bands_BandId",
                        column: x => x.BandId,
                        principalTable: "Bands",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_AttendanceRecords_Musicians_MusicianId",
                        column: x => x.MusicianId,
                        principalTable: "Musicians",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_AttendanceRecords_Musicians_RecordedByMusicianId",
                        column: x => x.RecordedByMusicianId,
                        principalTable: "Musicians",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "ConfigBand",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    BandId = table.Column<Guid>(type: "uuid", nullable: false),
                    Key = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Value = table.Column<string>(type: "jsonb", nullable: false),
                    UpdatedById = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ConfigBand", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ConfigBand_Bands_BandId",
                        column: x => x.BandId,
                        principalTable: "Bands",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ConfigBand_Musicians_UpdatedById",
                        column: x => x.UpdatedById,
                        principalTable: "Musicians",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateTable(
                name: "ConfigPolicies",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    BandId = table.Column<Guid>(type: "uuid", nullable: false),
                    Key = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Value = table.Column<string>(type: "jsonb", nullable: false),
                    UpdatedById = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ConfigPolicies", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ConfigPolicies_Bands_BandId",
                        column: x => x.BandId,
                        principalTable: "Bands",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ConfigPolicies_Musicians_UpdatedById",
                        column: x => x.UpdatedById,
                        principalTable: "Musicians",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateTable(
                name: "ConfigUser",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    MusicianId = table.Column<Guid>(type: "uuid", nullable: false),
                    Key = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Value = table.Column<string>(type: "jsonb", nullable: false),
                    Version = table.Column<long>(type: "bigint", nullable: false, defaultValue: 1L),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ConfigUser", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ConfigUser_Musicians_MusicianId",
                        column: x => x.MusicianId,
                        principalTable: "Musicians",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Invitations",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Code = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    BandId = table.Column<Guid>(type: "uuid", nullable: false),
                    IntendedRole = table.Column<int>(type: "integer", nullable: false),
                    ExpiresAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsUsed = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedByMusicianId = table.Column<Guid>(type: "uuid", nullable: false),
                    RedeemedByMusicianId = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Invitations", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Invitations_Bands_BandId",
                        column: x => x.BandId,
                        principalTable: "Bands",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Invitations_Musicians_CreatedByMusicianId",
                        column: x => x.CreatedByMusicianId,
                        principalTable: "Musicians",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Invitations_Musicians_RedeemedByMusicianId",
                        column: x => x.RedeemedByMusicianId,
                        principalTable: "Musicians",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateTable(
                name: "Memberships",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    MusicianId = table.Column<Guid>(type: "uuid", nullable: false),
                    BandId = table.Column<Guid>(type: "uuid", nullable: false),
                    Role = table.Column<int>(type: "integer", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    VoiceOverride = table.Column<string>(type: "text", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Memberships", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Memberships_Bands_BandId",
                        column: x => x.BandId,
                        principalTable: "Bands",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Memberships_Musicians_MusicianId",
                        column: x => x.MusicianId,
                        principalTable: "Musicians",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Pieces",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    BandId = table.Column<Guid>(type: "uuid", nullable: true),
                    MusicianId = table.Column<Guid>(type: "uuid", nullable: true),
                    Title = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Composer = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    Arranger = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    PublicationYear = table.Column<int>(type: "integer", nullable: true),
                    MusicalKey = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    TimeSignature = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    Tempo = table.Column<int>(type: "integer", nullable: true),
                    Description = table.Column<string>(type: "character varying(2000)", maxLength: 2000, nullable: true),
                    OriginalFileName = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    StorageKey = table.Column<string>(type: "character varying(1024)", maxLength: 1024, nullable: true),
                    ImportStatus = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Pieces", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Pieces_Bands_BandId",
                        column: x => x.BandId,
                        principalTable: "Bands",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Pieces_Musicians_MusicianId",
                        column: x => x.MusicianId,
                        principalTable: "Musicians",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateTable(
                name: "Polls",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    BandId = table.Column<Guid>(type: "uuid", nullable: false),
                    CreatedByMusicianId = table.Column<Guid>(type: "uuid", nullable: false),
                    Question = table.Column<string>(type: "character varying(250)", maxLength: 250, nullable: false),
                    IsAnonymous = table.Column<bool>(type: "boolean", nullable: false),
                    IsMultipleChoice = table.Column<bool>(type: "boolean", nullable: false),
                    ExpiresAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    IsClosed = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Polls", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Polls_Bands_BandId",
                        column: x => x.BandId,
                        principalTable: "Bands",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Polls_Musicians_CreatedByMusicianId",
                        column: x => x.CreatedByMusicianId,
                        principalTable: "Musicians",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "Posts",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    BandId = table.Column<Guid>(type: "uuid", nullable: false),
                    AuthorMusicianId = table.Column<Guid>(type: "uuid", nullable: false),
                    Title = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                    Content = table.Column<string>(type: "character varying(5000)", maxLength: 5000, nullable: false),
                    IsPinned = table.Column<bool>(type: "boolean", nullable: false),
                    PinnedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    Category = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Posts", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Posts_Bands_BandId",
                        column: x => x.BandId,
                        principalTable: "Bands",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Posts_Musicians_AuthorMusicianId",
                        column: x => x.AuthorMusicianId,
                        principalTable: "Musicians",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "UserInstruments",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    MusicianId = table.Column<Guid>(type: "uuid", nullable: false),
                    InstrumentType = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    InstrumentLabel = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    SortOrder = table.Column<int>(type: "integer", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserInstruments", x => x.Id);
                    table.ForeignKey(
                        name: "FK_UserInstruments_Musicians_MusicianId",
                        column: x => x.MusicianId,
                        principalTable: "Musicians",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Events",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    BandId = table.Column<Guid>(type: "uuid", nullable: false),
                    Title = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    Description = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true),
                    EventType = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false),
                    Location = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    StartDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    EndDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    IsAllDay = table.Column<bool>(type: "boolean", nullable: false),
                    RepeatRule = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    SetlistId = table.Column<Guid>(type: "uuid", nullable: true),
                    Notes = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    DressCode = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    MeetingPoint = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    RsvpDeadline = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CreatedByMusicianId = table.Column<Guid>(type: "uuid", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Events", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Events_Bands_BandId",
                        column: x => x.BandId,
                        principalTable: "Bands",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Events_Musicians_CreatedByMusicianId",
                        column: x => x.CreatedByMusicianId,
                        principalTable: "Musicians",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Events_Setlists_SetlistId",
                        column: x => x.SetlistId,
                        principalTable: "Setlists",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateTable(
                name: "MediaLinks",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    PieceId = table.Column<Guid>(type: "uuid", nullable: false),
                    BandId = table.Column<Guid>(type: "uuid", nullable: false),
                    Url = table.Column<string>(type: "character varying(2048)", maxLength: 2048, nullable: false),
                    Type = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false),
                    Title = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    Description = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    ThumbnailUrl = table.Column<string>(type: "character varying(2048)", maxLength: 2048, nullable: true),
                    DurationSeconds = table.Column<int>(type: "integer", nullable: true),
                    AddedByMusicianId = table.Column<Guid>(type: "uuid", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MediaLinks", x => x.Id);
                    table.ForeignKey(
                        name: "FK_MediaLinks_Bands_BandId",
                        column: x => x.BandId,
                        principalTable: "Bands",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_MediaLinks_Musicians_AddedByMusicianId",
                        column: x => x.AddedByMusicianId,
                        principalTable: "Musicians",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_MediaLinks_Pieces_PieceId",
                        column: x => x.PieceId,
                        principalTable: "Pieces",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "PiecePages",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    PieceId = table.Column<Guid>(type: "uuid", nullable: false),
                    PageNumber = table.Column<int>(type: "integer", nullable: false),
                    StorageKey = table.Column<string>(type: "character varying(1024)", maxLength: 1024, nullable: false),
                    OcrText = table.Column<string>(type: "text", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PiecePages", x => x.Id);
                    table.ForeignKey(
                        name: "FK_PiecePages_Pieces_PieceId",
                        column: x => x.PieceId,
                        principalTable: "Pieces",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "SetlistEntries",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    SetlistId = table.Column<Guid>(type: "uuid", nullable: false),
                    PieceId = table.Column<Guid>(type: "uuid", nullable: true),
                    Position = table.Column<int>(type: "integer", nullable: false),
                    IsPlaceholder = table.Column<bool>(type: "boolean", nullable: false),
                    PlaceholderTitle = table.Column<string>(type: "character varying(150)", maxLength: 150, nullable: true),
                    PlaceholderComposer = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    Notes = table.Column<string>(type: "character varying(250)", maxLength: 250, nullable: true),
                    DurationSeconds = table.Column<int>(type: "integer", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SetlistEntries", x => x.Id);
                    table.ForeignKey(
                        name: "FK_SetlistEntries_Pieces_PieceId",
                        column: x => x.PieceId,
                        principalTable: "Pieces",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_SetlistEntries_Setlists_SetlistId",
                        column: x => x.SetlistId,
                        principalTable: "Setlists",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Voices",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    PieceId = table.Column<Guid>(type: "uuid", nullable: false),
                    Label = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    Instrument = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    InstrumentType = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    InstrumentFamily = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    VoiceNumber = table.Column<int>(type: "integer", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Voices", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Voices_Pieces_PieceId",
                        column: x => x.PieceId,
                        principalTable: "Pieces",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "PollOptions",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    PollId = table.Column<Guid>(type: "uuid", nullable: false),
                    Text = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Position = table.Column<int>(type: "integer", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PollOptions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_PollOptions_Polls_PollId",
                        column: x => x.PollId,
                        principalTable: "Polls",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "PostComments",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    PostId = table.Column<Guid>(type: "uuid", nullable: false),
                    AuthorMusicianId = table.Column<Guid>(type: "uuid", nullable: false),
                    Content = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: false),
                    ParentCommentId = table.Column<Guid>(type: "uuid", nullable: true),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PostComments", x => x.Id);
                    table.ForeignKey(
                        name: "FK_PostComments_Musicians_AuthorMusicianId",
                        column: x => x.AuthorMusicianId,
                        principalTable: "Musicians",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_PostComments_PostComments_ParentCommentId",
                        column: x => x.ParentCommentId,
                        principalTable: "PostComments",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_PostComments_Posts_PostId",
                        column: x => x.PostId,
                        principalTable: "Posts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "PostReactions",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    PostId = table.Column<Guid>(type: "uuid", nullable: false),
                    MusicianId = table.Column<Guid>(type: "uuid", nullable: false),
                    ReactionType = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PostReactions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_PostReactions_Musicians_MusicianId",
                        column: x => x.MusicianId,
                        principalTable: "Musicians",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_PostReactions_Posts_PostId",
                        column: x => x.PostId,
                        principalTable: "Posts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "VoicePreselections",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    MusicianId = table.Column<Guid>(type: "uuid", nullable: false),
                    BandId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserInstrumentID = table.Column<Guid>(type: "uuid", nullable: false),
                    VoiceLabel = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_VoicePreselections", x => x.Id);
                    table.ForeignKey(
                        name: "FK_VoicePreselections_Bands_BandId",
                        column: x => x.BandId,
                        principalTable: "Bands",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_VoicePreselections_Musicians_MusicianId",
                        column: x => x.MusicianId,
                        principalTable: "Musicians",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_VoicePreselections_UserInstruments_UserInstrumentID",
                        column: x => x.UserInstrumentID,
                        principalTable: "UserInstruments",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateTable(
                name: "EventRsvps",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    EventId = table.Column<Guid>(type: "uuid", nullable: false),
                    MusicianId = table.Column<Guid>(type: "uuid", nullable: false),
                    Status = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    Comment = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    RespondedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_EventRsvps", x => x.Id);
                    table.ForeignKey(
                        name: "FK_EventRsvps_Events_EventId",
                        column: x => x.EventId,
                        principalTable: "Events",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_EventRsvps_Musicians_MusicianId",
                        column: x => x.MusicianId,
                        principalTable: "Musicians",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "GemaReports",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    BandId = table.Column<Guid>(type: "uuid", nullable: false),
                    Title = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    EventId = table.Column<Guid>(type: "uuid", nullable: true),
                    ReportDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Status = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    GeneratedByMusicianId = table.Column<Guid>(type: "uuid", nullable: false),
                    ExportFormat = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: true),
                    EventLocation = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    EventCategory = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    Organizer = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    SetlistId = table.Column<Guid>(type: "uuid", nullable: true),
                    ExportedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_GemaReports", x => x.Id);
                    table.ForeignKey(
                        name: "FK_GemaReports_Bands_BandId",
                        column: x => x.BandId,
                        principalTable: "Bands",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_GemaReports_Events_EventId",
                        column: x => x.EventId,
                        principalTable: "Events",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_GemaReports_Musicians_GeneratedByMusicianId",
                        column: x => x.GeneratedByMusicianId,
                        principalTable: "Musicians",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_GemaReports_Setlists_SetlistId",
                        column: x => x.SetlistId,
                        principalTable: "Setlists",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateTable(
                name: "ShiftPlans",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    BandId = table.Column<Guid>(type: "uuid", nullable: false),
                    EventId = table.Column<Guid>(type: "uuid", nullable: true),
                    Title = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    Description = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    CreatedByMusicianId = table.Column<Guid>(type: "uuid", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ShiftPlans", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ShiftPlans_Bands_BandId",
                        column: x => x.BandId,
                        principalTable: "Bands",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ShiftPlans_Events_EventId",
                        column: x => x.EventId,
                        principalTable: "Events",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_ShiftPlans_Musicians_CreatedByMusicianId",
                        column: x => x.CreatedByMusicianId,
                        principalTable: "Musicians",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "SheetMusic",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    VoiceId = table.Column<Guid>(type: "uuid", nullable: false),
                    BlobUrl = table.Column<string>(type: "text", nullable: false),
                    ContentType = table.Column<string>(type: "text", nullable: true),
                    FileSizeBytes = table.Column<long>(type: "bigint", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SheetMusic", x => x.Id);
                    table.ForeignKey(
                        name: "FK_SheetMusic_Voices_VoiceId",
                        column: x => x.VoiceId,
                        principalTable: "Voices",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "SubstituteAccesses",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    BandId = table.Column<Guid>(type: "uuid", nullable: false),
                    Token = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: false),
                    Name = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    Email = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    VoiceId = table.Column<Guid>(type: "uuid", nullable: true),
                    EventId = table.Column<Guid>(type: "uuid", nullable: true),
                    GrantedByMusicianId = table.Column<Guid>(type: "uuid", nullable: false),
                    ExpiresAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    RevokedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    LastAccessedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    Instrument = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    Note = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SubstituteAccesses", x => x.Id);
                    table.ForeignKey(
                        name: "FK_SubstituteAccesses_Bands_BandId",
                        column: x => x.BandId,
                        principalTable: "Bands",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_SubstituteAccesses_Events_EventId",
                        column: x => x.EventId,
                        principalTable: "Events",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_SubstituteAccesses_Musicians_GrantedByMusicianId",
                        column: x => x.GrantedByMusicianId,
                        principalTable: "Musicians",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_SubstituteAccesses_Voices_VoiceId",
                        column: x => x.VoiceId,
                        principalTable: "Voices",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateTable(
                name: "PollVotes",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    PollOptionId = table.Column<Guid>(type: "uuid", nullable: false),
                    MusicianId = table.Column<Guid>(type: "uuid", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PollVotes", x => x.Id);
                    table.ForeignKey(
                        name: "FK_PollVotes_Musicians_MusicianId",
                        column: x => x.MusicianId,
                        principalTable: "Musicians",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_PollVotes_PollOptions_PollOptionId",
                        column: x => x.PollOptionId,
                        principalTable: "PollOptions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "GemaReportEntries",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    GemaReportId = table.Column<Guid>(type: "uuid", nullable: false),
                    PieceId = table.Column<Guid>(type: "uuid", nullable: true),
                    Composer = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Title = table.Column<string>(type: "character varying(300)", maxLength: 300, nullable: false),
                    Arranger = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    Publisher = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    DurationSeconds = table.Column<int>(type: "integer", nullable: true),
                    WorkNumber = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: true),
                    Position = table.Column<int>(type: "integer", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_GemaReportEntries", x => x.Id);
                    table.ForeignKey(
                        name: "FK_GemaReportEntries_GemaReports_GemaReportId",
                        column: x => x.GemaReportId,
                        principalTable: "GemaReports",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_GemaReportEntries_Pieces_PieceId",
                        column: x => x.PieceId,
                        principalTable: "Pieces",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateTable(
                name: "Shifts",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    ShiftPlanId = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "character varying(80)", maxLength: 80, nullable: false),
                    Description = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    StartTime = table.Column<TimeOnly>(type: "time without time zone", nullable: false),
                    EndTime = table.Column<TimeOnly>(type: "time without time zone", nullable: false),
                    RequiredCount = table.Column<int>(type: "integer", nullable: false),
                    VoiceId = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Shifts", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Shifts_ShiftPlans_ShiftPlanId",
                        column: x => x.ShiftPlanId,
                        principalTable: "ShiftPlans",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Shifts_Voices_VoiceId",
                        column: x => x.VoiceId,
                        principalTable: "Voices",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateTable(
                name: "ShiftAssignments",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    ShiftId = table.Column<Guid>(type: "uuid", nullable: false),
                    MusicianId = table.Column<Guid>(type: "uuid", nullable: false),
                    AssignedByMusicianId = table.Column<Guid>(type: "uuid", nullable: true),
                    Status = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    Notes = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ShiftAssignments", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ShiftAssignments_Musicians_AssignedByMusicianId",
                        column: x => x.AssignedByMusicianId,
                        principalTable: "Musicians",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_ShiftAssignments_Musicians_MusicianId",
                        column: x => x.MusicianId,
                        principalTable: "Musicians",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ShiftAssignments_Shifts_ShiftId",
                        column: x => x.ShiftId,
                        principalTable: "Shifts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_AttendanceRecords_BandId_Date",
                table: "AttendanceRecords",
                columns: new[] { "BandId", "Date" });

            migrationBuilder.CreateIndex(
                name: "IX_AttendanceRecords_BandId_MusicianId_Date",
                table: "AttendanceRecords",
                columns: new[] { "BandId", "MusicianId", "Date" });

            migrationBuilder.CreateIndex(
                name: "IX_AttendanceRecords_MusicianId",
                table: "AttendanceRecords",
                column: "MusicianId");

            migrationBuilder.CreateIndex(
                name: "IX_AttendanceRecords_RecordedByMusicianId",
                table: "AttendanceRecords",
                column: "RecordedByMusicianId");

            migrationBuilder.CreateIndex(
                name: "IX_BandVoiceMappings_BandId_Instrument",
                table: "BandVoiceMappings",
                columns: new[] { "BandId", "Instrument" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_ConfigAudit_BandId_Timestamp",
                table: "ConfigAudit",
                columns: new[] { "BandId", "Timestamp" },
                descending: new[] { false, true });

            migrationBuilder.CreateIndex(
                name: "IX_ConfigAudit_MusicianId_Timestamp",
                table: "ConfigAudit",
                columns: new[] { "MusicianId", "Timestamp" },
                descending: new[] { false, true });

            migrationBuilder.CreateIndex(
                name: "IX_ConfigBand_BandId_Key",
                table: "ConfigBand",
                columns: new[] { "BandId", "Key" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_ConfigBand_UpdatedById",
                table: "ConfigBand",
                column: "UpdatedById");

            migrationBuilder.CreateIndex(
                name: "IX_ConfigPolicies_BandId_Key",
                table: "ConfigPolicies",
                columns: new[] { "BandId", "Key" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_ConfigPolicies_UpdatedById",
                table: "ConfigPolicies",
                column: "UpdatedById");

            migrationBuilder.CreateIndex(
                name: "IX_ConfigUser_MusicianId_Key",
                table: "ConfigUser",
                columns: new[] { "MusicianId", "Key" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_EventRsvps_EventId_MusicianId",
                table: "EventRsvps",
                columns: new[] { "EventId", "MusicianId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_EventRsvps_MusicianId",
                table: "EventRsvps",
                column: "MusicianId");

            migrationBuilder.CreateIndex(
                name: "IX_Events_BandId_StartDate",
                table: "Events",
                columns: new[] { "BandId", "StartDate" });

            migrationBuilder.CreateIndex(
                name: "IX_Events_CreatedByMusicianId",
                table: "Events",
                column: "CreatedByMusicianId");

            migrationBuilder.CreateIndex(
                name: "IX_Events_SetlistId",
                table: "Events",
                column: "SetlistId");

            migrationBuilder.CreateIndex(
                name: "IX_GemaReportEntries_GemaReportId_Position",
                table: "GemaReportEntries",
                columns: new[] { "GemaReportId", "Position" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_GemaReportEntries_PieceId",
                table: "GemaReportEntries",
                column: "PieceId");

            migrationBuilder.CreateIndex(
                name: "IX_GemaReports_BandId_ReportDate",
                table: "GemaReports",
                columns: new[] { "BandId", "ReportDate" });

            migrationBuilder.CreateIndex(
                name: "IX_GemaReports_EventId",
                table: "GemaReports",
                column: "EventId");

            migrationBuilder.CreateIndex(
                name: "IX_GemaReports_GeneratedByMusicianId",
                table: "GemaReports",
                column: "GeneratedByMusicianId");

            migrationBuilder.CreateIndex(
                name: "IX_GemaReports_SetlistId",
                table: "GemaReports",
                column: "SetlistId");

            migrationBuilder.CreateIndex(
                name: "IX_Invitations_BandId",
                table: "Invitations",
                column: "BandId");

            migrationBuilder.CreateIndex(
                name: "IX_Invitations_Code",
                table: "Invitations",
                column: "Code",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Invitations_CreatedByMusicianId",
                table: "Invitations",
                column: "CreatedByMusicianId");

            migrationBuilder.CreateIndex(
                name: "IX_Invitations_RedeemedByMusicianId",
                table: "Invitations",
                column: "RedeemedByMusicianId");

            migrationBuilder.CreateIndex(
                name: "IX_MediaLinks_AddedByMusicianId",
                table: "MediaLinks",
                column: "AddedByMusicianId");

            migrationBuilder.CreateIndex(
                name: "IX_MediaLinks_BandId",
                table: "MediaLinks",
                column: "BandId");

            migrationBuilder.CreateIndex(
                name: "IX_MediaLinks_PieceId_Url",
                table: "MediaLinks",
                columns: new[] { "PieceId", "Url" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Memberships_BandId",
                table: "Memberships",
                column: "BandId");

            migrationBuilder.CreateIndex(
                name: "IX_Memberships_MusicianId_BandId",
                table: "Memberships",
                columns: new[] { "MusicianId", "BandId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Musicians_Email",
                table: "Musicians",
                column: "Email",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Musicians_PasswordResetToken",
                table: "Musicians",
                column: "PasswordResetToken",
                unique: true,
                filter: "\"PasswordResetToken\" IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_PiecePages_PieceId_PageNumber",
                table: "PiecePages",
                columns: new[] { "PieceId", "PageNumber" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Pieces_BandId",
                table: "Pieces",
                column: "BandId");

            migrationBuilder.CreateIndex(
                name: "IX_Pieces_MusicianId",
                table: "Pieces",
                column: "MusicianId");

            migrationBuilder.CreateIndex(
                name: "IX_PollOptions_PollId_Position",
                table: "PollOptions",
                columns: new[] { "PollId", "Position" });

            migrationBuilder.CreateIndex(
                name: "IX_Polls_BandId_IsClosed",
                table: "Polls",
                columns: new[] { "BandId", "IsClosed" });

            migrationBuilder.CreateIndex(
                name: "IX_Polls_CreatedByMusicianId",
                table: "Polls",
                column: "CreatedByMusicianId");

            migrationBuilder.CreateIndex(
                name: "IX_PollVotes_MusicianId",
                table: "PollVotes",
                column: "MusicianId");

            migrationBuilder.CreateIndex(
                name: "IX_PollVotes_PollOptionId_MusicianId",
                table: "PollVotes",
                columns: new[] { "PollOptionId", "MusicianId" });

            migrationBuilder.CreateIndex(
                name: "IX_PostComments_AuthorMusicianId",
                table: "PostComments",
                column: "AuthorMusicianId");

            migrationBuilder.CreateIndex(
                name: "IX_PostComments_ParentCommentId",
                table: "PostComments",
                column: "ParentCommentId");

            migrationBuilder.CreateIndex(
                name: "IX_PostComments_PostId",
                table: "PostComments",
                column: "PostId");

            migrationBuilder.CreateIndex(
                name: "IX_PostReactions_MusicianId",
                table: "PostReactions",
                column: "MusicianId");

            migrationBuilder.CreateIndex(
                name: "IX_PostReactions_PostId_MusicianId",
                table: "PostReactions",
                columns: new[] { "PostId", "MusicianId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Posts_AuthorMusicianId",
                table: "Posts",
                column: "AuthorMusicianId");

            migrationBuilder.CreateIndex(
                name: "IX_Posts_BandId_IsPinned_CreatedAt",
                table: "Posts",
                columns: new[] { "BandId", "IsPinned", "CreatedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_SetlistEntries_PieceId",
                table: "SetlistEntries",
                column: "PieceId");

            migrationBuilder.CreateIndex(
                name: "IX_SetlistEntries_SetlistId_Position",
                table: "SetlistEntries",
                columns: new[] { "SetlistId", "Position" });

            migrationBuilder.CreateIndex(
                name: "IX_Setlists_BandId",
                table: "Setlists",
                column: "BandId");

            migrationBuilder.CreateIndex(
                name: "IX_SheetMusic_VoiceId",
                table: "SheetMusic",
                column: "VoiceId");

            migrationBuilder.CreateIndex(
                name: "IX_ShiftAssignments_AssignedByMusicianId",
                table: "ShiftAssignments",
                column: "AssignedByMusicianId");

            migrationBuilder.CreateIndex(
                name: "IX_ShiftAssignments_MusicianId",
                table: "ShiftAssignments",
                column: "MusicianId");

            migrationBuilder.CreateIndex(
                name: "IX_ShiftAssignments_ShiftId_MusicianId",
                table: "ShiftAssignments",
                columns: new[] { "ShiftId", "MusicianId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_ShiftPlans_BandId",
                table: "ShiftPlans",
                column: "BandId");

            migrationBuilder.CreateIndex(
                name: "IX_ShiftPlans_CreatedByMusicianId",
                table: "ShiftPlans",
                column: "CreatedByMusicianId");

            migrationBuilder.CreateIndex(
                name: "IX_ShiftPlans_EventId",
                table: "ShiftPlans",
                column: "EventId");

            migrationBuilder.CreateIndex(
                name: "IX_Shifts_ShiftPlanId",
                table: "Shifts",
                column: "ShiftPlanId");

            migrationBuilder.CreateIndex(
                name: "IX_Shifts_VoiceId",
                table: "Shifts",
                column: "VoiceId");

            migrationBuilder.CreateIndex(
                name: "IX_SubstituteAccesses_BandId_IsActive",
                table: "SubstituteAccesses",
                columns: new[] { "BandId", "IsActive" });

            migrationBuilder.CreateIndex(
                name: "IX_SubstituteAccesses_EventId",
                table: "SubstituteAccesses",
                column: "EventId");

            migrationBuilder.CreateIndex(
                name: "IX_SubstituteAccesses_GrantedByMusicianId",
                table: "SubstituteAccesses",
                column: "GrantedByMusicianId");

            migrationBuilder.CreateIndex(
                name: "IX_SubstituteAccesses_Token",
                table: "SubstituteAccesses",
                column: "Token",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_SubstituteAccesses_VoiceId",
                table: "SubstituteAccesses",
                column: "VoiceId");

            migrationBuilder.CreateIndex(
                name: "IX_UserInstruments_MusicianId",
                table: "UserInstruments",
                column: "MusicianId");

            migrationBuilder.CreateIndex(
                name: "IX_UserInstruments_MusicianId_InstrumentType",
                table: "UserInstruments",
                columns: new[] { "MusicianId", "InstrumentType" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_VoicePreselections_BandId",
                table: "VoicePreselections",
                column: "BandId");

            migrationBuilder.CreateIndex(
                name: "IX_VoicePreselections_MusicianId_BandId",
                table: "VoicePreselections",
                columns: new[] { "MusicianId", "BandId" });

            migrationBuilder.CreateIndex(
                name: "IX_VoicePreselections_MusicianId_BandId_UserInstrumentID",
                table: "VoicePreselections",
                columns: new[] { "MusicianId", "BandId", "UserInstrumentID" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_VoicePreselections_UserInstrumentID",
                table: "VoicePreselections",
                column: "UserInstrumentID");

            migrationBuilder.CreateIndex(
                name: "IX_Voices_PieceId_InstrumentType_VoiceNumber",
                table: "Voices",
                columns: new[] { "PieceId", "InstrumentType", "VoiceNumber" });

            migrationBuilder.CreateIndex(
                name: "IX_Voices_PieceId_Label",
                table: "Voices",
                columns: new[] { "PieceId", "Label" },
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_RefreshTokens_Musicians_MusicianId",
                table: "RefreshTokens",
                column: "MusicianId",
                principalTable: "Musicians",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_RefreshTokens_Musicians_MusicianId",
                table: "RefreshTokens");

            migrationBuilder.DropTable(
                name: "AttendanceRecords");

            migrationBuilder.DropTable(
                name: "BandVoiceMappings");

            migrationBuilder.DropTable(
                name: "ConfigAudit");

            migrationBuilder.DropTable(
                name: "ConfigBand");

            migrationBuilder.DropTable(
                name: "ConfigPolicies");

            migrationBuilder.DropTable(
                name: "ConfigUser");

            migrationBuilder.DropTable(
                name: "EventRsvps");

            migrationBuilder.DropTable(
                name: "GemaReportEntries");

            migrationBuilder.DropTable(
                name: "Invitations");

            migrationBuilder.DropTable(
                name: "MediaLinks");

            migrationBuilder.DropTable(
                name: "Memberships");

            migrationBuilder.DropTable(
                name: "PiecePages");

            migrationBuilder.DropTable(
                name: "PollVotes");

            migrationBuilder.DropTable(
                name: "PostComments");

            migrationBuilder.DropTable(
                name: "PostReactions");

            migrationBuilder.DropTable(
                name: "SetlistEntries");

            migrationBuilder.DropTable(
                name: "SheetMusic");

            migrationBuilder.DropTable(
                name: "ShiftAssignments");

            migrationBuilder.DropTable(
                name: "SubstituteAccesses");

            migrationBuilder.DropTable(
                name: "VoicePreselections");

            migrationBuilder.DropTable(
                name: "GemaReports");

            migrationBuilder.DropTable(
                name: "PollOptions");

            migrationBuilder.DropTable(
                name: "Posts");

            migrationBuilder.DropTable(
                name: "Shifts");

            migrationBuilder.DropTable(
                name: "UserInstruments");

            migrationBuilder.DropTable(
                name: "Polls");

            migrationBuilder.DropTable(
                name: "ShiftPlans");

            migrationBuilder.DropTable(
                name: "Voices");

            migrationBuilder.DropTable(
                name: "Events");

            migrationBuilder.DropTable(
                name: "Pieces");

            migrationBuilder.DropTable(
                name: "Setlists");

            migrationBuilder.DropTable(
                name: "Musicians");

            migrationBuilder.DropTable(
                name: "Bands");

            migrationBuilder.RenameColumn(
                name: "MusicianId",
                table: "RefreshTokens",
                newName: "MusikerId");

            migrationBuilder.RenameIndex(
                name: "IX_RefreshTokens_MusicianId",
                table: "RefreshTokens",
                newName: "IX_RefreshTokens_MusikerId");

            migrationBuilder.CreateTable(
                name: "Kapellen",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Beschreibung = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    LogoUrl = table.Column<string>(type: "character varying(512)", maxLength: 512, nullable: true),
                    Name = table.Column<string>(type: "character varying(80)", maxLength: 80, nullable: false),
                    Ort = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
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
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Email = table.Column<string>(type: "character varying(256)", maxLength: 256, nullable: false),
                    EmailVerificationToken = table.Column<string>(type: "text", nullable: true),
                    EmailVerificationTokenExpiresAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    EmailVerified = table.Column<bool>(type: "boolean", nullable: false),
                    Instrument = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    Name = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    OnboardingCompleted = table.Column<bool>(type: "boolean", nullable: false),
                    PasswordHash = table.Column<string>(type: "text", nullable: false),
                    PasswordResetRequestedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    PasswordResetToken = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: true),
                    PasswordResetTokenExpiresAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
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
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Instrument = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    Stimme = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
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
                    EingeloestVonMusikerID = table.Column<Guid>(type: "uuid", nullable: true),
                    ErstelltVonMusikerID = table.Column<Guid>(type: "uuid", nullable: false),
                    KapelleID = table.Column<Guid>(type: "uuid", nullable: false),
                    Code = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ExpiresAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsUsed = table.Column<bool>(type: "boolean", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    VorgeseheRolle = table.Column<int>(type: "integer", nullable: false)
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
                    KapelleID = table.Column<Guid>(type: "uuid", nullable: false),
                    MusikerID = table.Column<Guid>(type: "uuid", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IstAktiv = table.Column<bool>(type: "boolean", nullable: false),
                    Rolle = table.Column<int>(type: "integer", nullable: false),
                    StimmenOverride = table.Column<string>(type: "text", nullable: true),
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
                name: "Stuecke",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    KapelleID = table.Column<Guid>(type: "uuid", nullable: true),
                    MusikerID = table.Column<Guid>(type: "uuid", nullable: true),
                    Arrangeur = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    Beschreibung = table.Column<string>(type: "character varying(2000)", maxLength: 2000, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ImportStatus = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    Komponist = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    OriginalDateiname = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    StorageKey = table.Column<string>(type: "character varying(1024)", maxLength: 1024, nullable: true),
                    Taktart = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    Tempo = table.Column<int>(type: "integer", nullable: true),
                    Titel = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Tonart = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    VeroeffentlichungsJahr = table.Column<int>(type: "integer", nullable: true)
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
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Instrument = table.Column<string>(type: "text", nullable: true),
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
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    OcrText = table.Column<string>(type: "text", nullable: true),
                    Seitennummer = table.Column<int>(type: "integer", nullable: false),
                    StorageKey = table.Column<string>(type: "character varying(1024)", maxLength: 1024, nullable: false),
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
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    FileSizeBytes = table.Column<long>(type: "bigint", nullable: true),
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

            migrationBuilder.AddForeignKey(
                name: "FK_RefreshTokens_Musiker_MusikerId",
                table: "RefreshTokens",
                column: "MusikerId",
                principalTable: "Musiker",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
