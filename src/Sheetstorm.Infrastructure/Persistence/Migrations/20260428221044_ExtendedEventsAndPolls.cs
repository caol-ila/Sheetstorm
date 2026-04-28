using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Sheetstorm.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class ExtendedEventsAndPolls : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "IsTentative",
                table: "ShiftAssignments",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "IsStub",
                table: "OmrJobs",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<Guid>(
                name: "EventDayId",
                table: "EventShifts",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Notes",
                table: "EventShifts",
                type: "character varying(2000)",
                maxLength: 2000,
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "StationId",
                table: "EventShifts",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "EventContributions",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    EventId = table.Column<Guid>(type: "uuid", nullable: false),
                    Title = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Description = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true),
                    Unit = table.Column<int>(type: "integer", nullable: false),
                    Wanted = table.Column<int>(type: "integer", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_EventContributions", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "EventDays",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    EventId = table.Column<Guid>(type: "uuid", nullable: false),
                    Date = table.Column<DateOnly>(type: "date", nullable: false),
                    Theme = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    OpenAt = table.Column<TimeOnly>(type: "time without time zone", nullable: true),
                    CloseAt = table.Column<TimeOnly>(type: "time without time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_EventDays", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "EventPolls",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    EventId = table.Column<Guid>(type: "uuid", nullable: true),
                    BandId = table.Column<Guid>(type: "uuid", nullable: true),
                    Kind = table.Column<int>(type: "integer", nullable: false),
                    Title = table.Column<string>(type: "character varying(300)", maxLength: 300, nullable: false),
                    Description = table.Column<string>(type: "character varying(2000)", maxLength: 2000, nullable: true),
                    ClosesAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    CreatedByUserId = table.Column<Guid>(type: "uuid", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    AllowMultiple = table.Column<bool>(type: "boolean", nullable: false),
                    AnonymousResults = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_EventPolls", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "EventStations",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    EventId = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Description = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true),
                    IconKey = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_EventStations", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "EventContributionPledges",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    ContributionId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    What = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    Quantity = table.Column<int>(type: "integer", nullable: false),
                    PledgedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_EventContributionPledges", x => x.Id);
                    table.ForeignKey(
                        name: "FK_EventContributionPledges_EventContributions_ContributionId",
                        column: x => x.ContributionId,
                        principalTable: "EventContributions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "PollOptions",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    PollId = table.Column<Guid>(type: "uuid", nullable: false),
                    Label = table.Column<string>(type: "character varying(300)", maxLength: 300, nullable: false),
                    AsDateTime = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    Order = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PollOptions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_PollOptions_EventPolls_PollId",
                        column: x => x.PollId,
                        principalTable: "EventPolls",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "PollResponses",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    PollId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    OptionId = table.Column<Guid>(type: "uuid", nullable: true),
                    Answer = table.Column<int>(type: "integer", nullable: false),
                    FreeTextAnswer = table.Column<string>(type: "character varying(2000)", maxLength: 2000, nullable: true),
                    Size = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: true),
                    Quantity = table.Column<int>(type: "integer", nullable: true),
                    RespondedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PollResponses", x => x.Id);
                    table.ForeignKey(
                        name: "FK_PollResponses_EventPolls_PollId",
                        column: x => x.PollId,
                        principalTable: "EventPolls",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_PollResponses_PollOptions_OptionId",
                        column: x => x.OptionId,
                        principalTable: "PollOptions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateIndex(
                name: "IX_EventShifts_EventDayId",
                table: "EventShifts",
                column: "EventDayId");

            migrationBuilder.CreateIndex(
                name: "IX_EventShifts_StationId",
                table: "EventShifts",
                column: "StationId");

            migrationBuilder.CreateIndex(
                name: "IX_EventContributionPledges_ContributionId_UserId",
                table: "EventContributionPledges",
                columns: new[] { "ContributionId", "UserId" });

            migrationBuilder.CreateIndex(
                name: "IX_EventContributions_EventId",
                table: "EventContributions",
                column: "EventId");

            migrationBuilder.CreateIndex(
                name: "IX_EventDays_EventId",
                table: "EventDays",
                column: "EventId");

            migrationBuilder.CreateIndex(
                name: "IX_EventPolls_BandId",
                table: "EventPolls",
                column: "BandId");

            migrationBuilder.CreateIndex(
                name: "IX_EventPolls_EventId",
                table: "EventPolls",
                column: "EventId");

            migrationBuilder.CreateIndex(
                name: "IX_EventStations_EventId",
                table: "EventStations",
                column: "EventId");

            migrationBuilder.CreateIndex(
                name: "IX_PollOptions_PollId",
                table: "PollOptions",
                column: "PollId");

            migrationBuilder.CreateIndex(
                name: "IX_PollResponses_OptionId",
                table: "PollResponses",
                column: "OptionId");

            migrationBuilder.CreateIndex(
                name: "IX_PollResponses_PollId_UserId",
                table: "PollResponses",
                columns: new[] { "PollId", "UserId" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "EventContributionPledges");

            migrationBuilder.DropTable(
                name: "EventDays");

            migrationBuilder.DropTable(
                name: "EventStations");

            migrationBuilder.DropTable(
                name: "PollResponses");

            migrationBuilder.DropTable(
                name: "EventContributions");

            migrationBuilder.DropTable(
                name: "PollOptions");

            migrationBuilder.DropTable(
                name: "EventPolls");

            migrationBuilder.DropIndex(
                name: "IX_EventShifts_EventDayId",
                table: "EventShifts");

            migrationBuilder.DropIndex(
                name: "IX_EventShifts_StationId",
                table: "EventShifts");

            migrationBuilder.DropColumn(
                name: "IsTentative",
                table: "ShiftAssignments");

            migrationBuilder.DropColumn(
                name: "IsStub",
                table: "OmrJobs");

            migrationBuilder.DropColumn(
                name: "EventDayId",
                table: "EventShifts");

            migrationBuilder.DropColumn(
                name: "Notes",
                table: "EventShifts");

            migrationBuilder.DropColumn(
                name: "StationId",
                table: "EventShifts");
        }
    }
}
