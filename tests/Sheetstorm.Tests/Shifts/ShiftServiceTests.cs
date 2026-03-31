using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Domain.Enums;
using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Domain.Shifts;
using Sheetstorm.Infrastructure.Auth;
using Sheetstorm.Infrastructure.Persistence;
using Sheetstorm.Infrastructure.Shifts;

namespace Sheetstorm.Tests.Shifts;

public class ShiftServiceTests : IDisposable
{
    private readonly AppDbContext _db;
    private readonly ShiftService _sut;

    public ShiftServiceTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        _db = new AppDbContext(options);
        _sut = new ShiftService(_db, new BandAuthorizationService(_db));
    }

    public void Dispose()
    {
        _db.Dispose();
        GC.SuppressFinalize(this);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private async Task<(Guid musicianId, Guid bandId, Guid planId)> SeedPlanAsync(MemberRole role = MemberRole.Conductor)
    {
        var musician = new Musician { Email = $"m{Guid.NewGuid()}@test.com", Name = "Test Musician" };
        var band = new Band { Name = "Test Band" };
        var membership = new Membership { Musician = musician, Band = band, Role = role, IsActive = true };
        var plan = new ShiftPlan { Band = band, CreatedByMusician = musician, Title = "Test Plan" };
        _db.Musicians.Add(musician);
        _db.Bands.Add(band);
        _db.Memberships.Add(membership);
        _db.ShiftPlans.Add(plan);
        await _db.SaveChangesAsync();
        return (musician.Id, band.Id, plan.Id);
    }

    private async Task<Guid> SeedAdditionalMemberAsync(Guid bandId, MemberRole role = MemberRole.Musician)
    {
        var musician = new Musician { Email = $"m{Guid.NewGuid()}@test.com", Name = "Additional Member" };
        var membership = new Membership { MusicianId = musician.Id, BandId = bandId, Role = role, IsActive = true };
        _db.Musicians.Add(musician);
        _db.Memberships.Add(membership);
        await _db.SaveChangesAsync();
        return musician.Id;
    }

    // ── CreateShiftPlanAsync ──────────────────────────────────────────────────

    [Fact]
    public async Task CreateShiftPlanAsync_Conductor_CreatesPlan()
    {
        var (conductorId, bandId, _) = await SeedPlanAsync(MemberRole.Conductor);

        var request = new CreateShiftPlanRequest("New Plan", "Description", null);
        var result = await _sut.CreateShiftPlanAsync(bandId, request, conductorId, CancellationToken.None);

        Assert.Equal("New Plan", result.Title);
        Assert.Equal("Description", result.Description);
    }

    [Fact]
    public async Task CreateShiftPlanAsync_Admin_CreatesPlan()
    {
        var (adminId, bandId, _) = await SeedPlanAsync(MemberRole.Administrator);

        var request = new CreateShiftPlanRequest("Admin Plan", null, null);
        var result = await _sut.CreateShiftPlanAsync(bandId, request, adminId, CancellationToken.None);

        Assert.Equal("Admin Plan", result.Title);
    }

    [Fact]
    public async Task CreateShiftPlanAsync_RegularMember_ThrowsForbidden()
    {
        var (_, bandId, _) = await SeedPlanAsync(MemberRole.Conductor);
        var memberId = await SeedAdditionalMemberAsync(bandId, MemberRole.Musician);

        var request = new CreateShiftPlanRequest("Plan", null, null);
        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.CreateShiftPlanAsync(bandId, request, memberId, CancellationToken.None));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
    }

    // ── GetShiftPlansAsync ────────────────────────────────────────────────────

    [Fact]
    public async Task GetShiftPlansAsync_ReturnsAllPlans()
    {
        var (musicianId, bandId, planId) = await SeedPlanAsync();
        var plan2 = new ShiftPlan { BandId = bandId, CreatedByMusicianId = musicianId, Title = "Plan 2" };
        _db.ShiftPlans.Add(plan2);
        await _db.SaveChangesAsync();

        var result = await _sut.GetShiftPlansAsync(bandId, musicianId, CancellationToken.None);

        Assert.Equal(2, result.Count);
    }

    [Fact]
    public async Task GetShiftPlansAsync_NotMember_ThrowsDomainException()
    {
        var (_, bandId, _) = await SeedPlanAsync();
        var stranger = Guid.NewGuid();

        await Assert.ThrowsAsync<DomainException>(() =>
            _sut.GetShiftPlansAsync(bandId, stranger, CancellationToken.None));
    }

    // ── UpdateShiftPlanAsync ──────────────────────────────────────────────────

    [Fact]
    public async Task UpdateShiftPlanAsync_Conductor_UpdatesPlan()
    {
        var (conductorId, bandId, planId) = await SeedPlanAsync();

        var request = new UpdateShiftPlanRequest("Updated Title", "Updated Desc", null);
        var result = await _sut.UpdateShiftPlanAsync(bandId, planId, request, conductorId, CancellationToken.None);

        Assert.Equal("Updated Title", result.Title);
        Assert.Equal("Updated Desc", result.Description);
    }

    [Fact]
    public async Task UpdateShiftPlanAsync_RegularMember_ThrowsForbidden()
    {
        var (_, bandId, planId) = await SeedPlanAsync();
        var memberId = await SeedAdditionalMemberAsync(bandId);

        var request = new UpdateShiftPlanRequest("Title", null, null);
        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.UpdateShiftPlanAsync(bandId, planId, request, memberId, CancellationToken.None));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
    }

    // ── DeleteShiftPlanAsync ──────────────────────────────────────────────────

    [Fact]
    public async Task DeleteShiftPlanAsync_Conductor_DeletesPlan()
    {
        var (conductorId, bandId, planId) = await SeedPlanAsync();

        await _sut.DeleteShiftPlanAsync(bandId, planId, conductorId, CancellationToken.None);

        var exists = await _db.ShiftPlans.AnyAsync(p => p.Id == planId);
        Assert.False(exists);
    }

    // ── CreateShiftAsync ──────────────────────────────────────────────────────

    [Fact]
    public async Task CreateShiftAsync_Conductor_CreatesShift()
    {
        var (conductorId, bandId, planId) = await SeedPlanAsync();

        var request = new CreateShiftRequest("Bar Duty", "Serve drinks", new TimeOnly(14, 0), new TimeOnly(18, 0), 3, null);
        var result = await _sut.CreateShiftAsync(bandId, planId, request, conductorId, CancellationToken.None);

        Assert.Equal("Bar Duty", result.Name);
        Assert.Equal(3, result.RequiredCount);
        Assert.Equal(0, result.AssignmentCount);
        Assert.Equal(3, result.OpenSlots);
    }

    [Fact]
    public async Task CreateShiftAsync_EndBeforeStart_ThrowsValidationError()
    {
        var (conductorId, bandId, planId) = await SeedPlanAsync();

        var request = new CreateShiftRequest("Shift", null, new TimeOnly(18, 0), new TimeOnly(14, 0), 1, null);
        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.CreateShiftAsync(bandId, planId, request, conductorId, CancellationToken.None));

        Assert.Equal("VALIDATION_ERROR", ex.ErrorCode);
    }

    [Fact]
    public async Task CreateShiftAsync_RegularMember_ThrowsForbidden()
    {
        var (_, bandId, planId) = await SeedPlanAsync();
        var memberId = await SeedAdditionalMemberAsync(bandId);

        var request = new CreateShiftRequest("Shift", null, new TimeOnly(14, 0), new TimeOnly(18, 0), 1, null);
        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.CreateShiftAsync(bandId, planId, request, memberId, CancellationToken.None));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
    }

    // ── GetShiftsAsync ────────────────────────────────────────────────────────

    [Fact]
    public async Task GetShiftsAsync_ReturnsAllShifts()
    {
        var (musicianId, bandId, planId) = await SeedPlanAsync();
        var shift1 = new Shift { ShiftPlanId = planId, Name = "Shift 1", StartTime = new TimeOnly(10, 0), EndTime = new TimeOnly(12, 0), RequiredCount = 2 };
        var shift2 = new Shift { ShiftPlanId = planId, Name = "Shift 2", StartTime = new TimeOnly(14, 0), EndTime = new TimeOnly(16, 0), RequiredCount = 3 };
        _db.Shifts.AddRange(shift1, shift2);
        await _db.SaveChangesAsync();

        var result = await _sut.GetShiftsAsync(bandId, planId, musicianId, CancellationToken.None);

        Assert.Equal(2, result.Count);
        Assert.Equal("Shift 1", result[0].Name);
    }

    // ── UpdateShiftAsync ──────────────────────────────────────────────────────

    [Fact]
    public async Task UpdateShiftAsync_Conductor_UpdatesShift()
    {
        var (conductorId, bandId, planId) = await SeedPlanAsync();
        var shift = new Shift { ShiftPlanId = planId, Name = "Old", StartTime = new TimeOnly(10, 0), EndTime = new TimeOnly(12, 0), RequiredCount = 1 };
        _db.Shifts.Add(shift);
        await _db.SaveChangesAsync();

        var request = new UpdateShiftRequest("Updated", "New desc", new TimeOnly(11, 0), new TimeOnly(13, 0), 5, null);
        var result = await _sut.UpdateShiftAsync(bandId, planId, shift.Id, request, conductorId, CancellationToken.None);

        Assert.Equal("Updated", result.Name);
        Assert.Equal(5, result.RequiredCount);
    }

    [Fact]
    public async Task UpdateShiftAsync_StartTimeAfterEndTime_ThrowsValidationError()
    {
        var (conductorId, bandId, planId) = await SeedPlanAsync();
        var shift = new Shift { ShiftPlanId = planId, Name = "Shift", StartTime = new TimeOnly(10, 0), EndTime = new TimeOnly(12, 0), RequiredCount = 1 };
        _db.Shifts.Add(shift);
        await _db.SaveChangesAsync();

        var request = new UpdateShiftRequest("Shift", null, new TimeOnly(18, 0), new TimeOnly(14, 0), 1, null);
        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.UpdateShiftAsync(bandId, planId, shift.Id, request, conductorId, CancellationToken.None));

        Assert.Equal("VALIDATION_ERROR", ex.ErrorCode);
        Assert.Equal(400, ex.StatusCode);
    }

    [Fact]
    public async Task UpdateShiftAsync_StartTimeEqualsEndTime_ThrowsValidationError()
    {
        var (conductorId, bandId, planId) = await SeedPlanAsync();
        var shift = new Shift { ShiftPlanId = planId, Name = "Shift", StartTime = new TimeOnly(10, 0), EndTime = new TimeOnly(12, 0), RequiredCount = 1 };
        _db.Shifts.Add(shift);
        await _db.SaveChangesAsync();

        var request = new UpdateShiftRequest("Shift", null, new TimeOnly(14, 0), new TimeOnly(14, 0), 1, null);
        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.UpdateShiftAsync(bandId, planId, shift.Id, request, conductorId, CancellationToken.None));

        Assert.Equal("VALIDATION_ERROR", ex.ErrorCode);
        Assert.Equal(400, ex.StatusCode);
    }

    [Fact]
    public async Task CreateShiftAsync_StartTimeEqualsEndTime_ThrowsValidationError()
    {
        var (conductorId, bandId, planId) = await SeedPlanAsync();

        var request = new CreateShiftRequest("Shift", null, new TimeOnly(14, 0), new TimeOnly(14, 0), 1, null);
        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.CreateShiftAsync(bandId, planId, request, conductorId, CancellationToken.None));

        Assert.Equal("VALIDATION_ERROR", ex.ErrorCode);
        Assert.Equal(400, ex.StatusCode);
    }

    // ── DeleteShiftAsync ──────────────────────────────────────────────────────

    [Fact]
    public async Task DeleteShiftAsync_Conductor_DeletesShift()
    {
        var (conductorId, bandId, planId) = await SeedPlanAsync();
        var shift = new Shift { ShiftPlanId = planId, Name = "Shift", StartTime = new TimeOnly(10, 0), EndTime = new TimeOnly(12, 0), RequiredCount = 1 };
        _db.Shifts.Add(shift);
        await _db.SaveChangesAsync();

        await _sut.DeleteShiftAsync(bandId, planId, shift.Id, conductorId, CancellationToken.None);

        var exists = await _db.Shifts.AnyAsync(s => s.Id == shift.Id);
        Assert.False(exists);
    }

    // ── CreateAssignmentAsync (Self-Signup) ───────────────────────────────────

    [Fact]
    public async Task CreateAssignmentAsync_SelfSignup_CreatesAssignment()
    {
        var (_, bandId, planId) = await SeedPlanAsync();
        var memberId = await SeedAdditionalMemberAsync(bandId);
        var shift = new Shift { ShiftPlanId = planId, Name = "Shift", StartTime = new TimeOnly(10, 0), EndTime = new TimeOnly(12, 0), RequiredCount = 2 };
        _db.Shifts.Add(shift);
        await _db.SaveChangesAsync();

        var request = new CreateShiftAssignmentRequest(null);
        var result = await _sut.CreateAssignmentAsync(bandId, planId, shift.Id, request, memberId, CancellationToken.None);

        Assert.Equal(memberId, result.MusicianId);
        Assert.Null(result.AssignedByMusicianId);
        Assert.Equal(ShiftAssignmentStatus.Assigned, result.Status);
    }

    [Fact]
    public async Task CreateAssignmentAsync_AdminAssignment_CreatesAssignment()
    {
        var (adminId, bandId, planId) = await SeedPlanAsync(MemberRole.Administrator);
        var memberId = await SeedAdditionalMemberAsync(bandId);
        var shift = new Shift { ShiftPlanId = planId, Name = "Shift", StartTime = new TimeOnly(10, 0), EndTime = new TimeOnly(12, 0), RequiredCount = 2 };
        _db.Shifts.Add(shift);
        await _db.SaveChangesAsync();

        var request = new CreateShiftAssignmentRequest(memberId);
        var result = await _sut.CreateAssignmentAsync(bandId, planId, shift.Id, request, adminId, CancellationToken.None);

        Assert.Equal(memberId, result.MusicianId);
        Assert.Equal(adminId, result.AssignedByMusicianId);
    }

    [Fact]
    public async Task CreateAssignmentAsync_RegularMemberAssigningOther_ThrowsForbidden()
    {
        var (_, bandId, planId) = await SeedPlanAsync();
        var member1 = await SeedAdditionalMemberAsync(bandId);
        var member2 = await SeedAdditionalMemberAsync(bandId);
        var shift = new Shift { ShiftPlanId = planId, Name = "Shift", StartTime = new TimeOnly(10, 0), EndTime = new TimeOnly(12, 0), RequiredCount = 2 };
        _db.Shifts.Add(shift);
        await _db.SaveChangesAsync();

        var request = new CreateShiftAssignmentRequest(member2);
        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.CreateAssignmentAsync(bandId, planId, shift.Id, request, member1, CancellationToken.None));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
    }

    [Fact]
    public async Task CreateAssignmentAsync_AlreadyAssigned_ThrowsConflict()
    {
        var (_, bandId, planId) = await SeedPlanAsync();
        var memberId = await SeedAdditionalMemberAsync(bandId);
        var shift = new Shift { ShiftPlanId = planId, Name = "Shift", StartTime = new TimeOnly(10, 0), EndTime = new TimeOnly(12, 0), RequiredCount = 2 };
        var assignment = new ShiftAssignment { Shift = shift, MusicianId = memberId, Status = ShiftAssignmentStatus.Assigned };
        _db.Shifts.Add(shift);
        _db.ShiftAssignments.Add(assignment);
        await _db.SaveChangesAsync();

        var request = new CreateShiftAssignmentRequest(null);
        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.CreateAssignmentAsync(bandId, planId, shift.Id, request, memberId, CancellationToken.None));

        Assert.Equal("CONFLICT", ex.ErrorCode);
        Assert.Equal(409, ex.StatusCode);
    }

    [Fact]
    public async Task CreateAssignmentAsync_ShiftFull_ThrowsConflict()
    {
        var (_, bandId, planId) = await SeedPlanAsync();
        var member1 = await SeedAdditionalMemberAsync(bandId);
        var member2 = await SeedAdditionalMemberAsync(bandId);
        var member3 = await SeedAdditionalMemberAsync(bandId);
        var shift = new Shift { ShiftPlanId = planId, Name = "Shift", StartTime = new TimeOnly(10, 0), EndTime = new TimeOnly(12, 0), RequiredCount = 2 };
        var assignment1 = new ShiftAssignment { Shift = shift, MusicianId = member1, Status = ShiftAssignmentStatus.Assigned };
        var assignment2 = new ShiftAssignment { Shift = shift, MusicianId = member2, Status = ShiftAssignmentStatus.Assigned };
        _db.Shifts.Add(shift);
        _db.ShiftAssignments.AddRange(assignment1, assignment2);
        await _db.SaveChangesAsync();

        var request = new CreateShiftAssignmentRequest(null);
        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.CreateAssignmentAsync(bandId, planId, shift.Id, request, member3, CancellationToken.None));

        Assert.Equal("CONFLICT", ex.ErrorCode);
        Assert.Contains("full", ex.Message, StringComparison.OrdinalIgnoreCase);
    }

    // ── DeleteAssignmentAsync ─────────────────────────────────────────────────

    [Fact]
    public async Task DeleteAssignmentAsync_OwnAssignment_DeletesIt()
    {
        var (_, bandId, planId) = await SeedPlanAsync();
        var memberId = await SeedAdditionalMemberAsync(bandId);
        var shift = new Shift { ShiftPlanId = planId, Name = "Shift", StartTime = new TimeOnly(10, 0), EndTime = new TimeOnly(12, 0), RequiredCount = 2 };
        var assignment = new ShiftAssignment { Shift = shift, MusicianId = memberId, Status = ShiftAssignmentStatus.Assigned };
        _db.Shifts.Add(shift);
        _db.ShiftAssignments.Add(assignment);
        await _db.SaveChangesAsync();

        await _sut.DeleteAssignmentAsync(bandId, planId, shift.Id, assignment.Id, memberId, CancellationToken.None);

        var exists = await _db.ShiftAssignments.AnyAsync(a => a.Id == assignment.Id);
        Assert.False(exists);
    }

    [Fact]
    public async Task DeleteAssignmentAsync_AdminRemovingOther_DeletesIt()
    {
        var (adminId, bandId, planId) = await SeedPlanAsync(MemberRole.Administrator);
        var memberId = await SeedAdditionalMemberAsync(bandId);
        var shift = new Shift { ShiftPlanId = planId, Name = "Shift", StartTime = new TimeOnly(10, 0), EndTime = new TimeOnly(12, 0), RequiredCount = 2 };
        var assignment = new ShiftAssignment { Shift = shift, MusicianId = memberId, Status = ShiftAssignmentStatus.Assigned };
        _db.Shifts.Add(shift);
        _db.ShiftAssignments.Add(assignment);
        await _db.SaveChangesAsync();

        await _sut.DeleteAssignmentAsync(bandId, planId, shift.Id, assignment.Id, adminId, CancellationToken.None);

        var exists = await _db.ShiftAssignments.AnyAsync(a => a.Id == assignment.Id);
        Assert.False(exists);
    }

    [Fact]
    public async Task DeleteAssignmentAsync_RegularMemberRemovingOther_ThrowsForbidden()
    {
        var (_, bandId, planId) = await SeedPlanAsync();
        var member1 = await SeedAdditionalMemberAsync(bandId);
        var member2 = await SeedAdditionalMemberAsync(bandId);
        var shift = new Shift { ShiftPlanId = planId, Name = "Shift", StartTime = new TimeOnly(10, 0), EndTime = new TimeOnly(12, 0), RequiredCount = 2 };
        var assignment = new ShiftAssignment { Shift = shift, MusicianId = member1, Status = ShiftAssignmentStatus.Assigned };
        _db.Shifts.Add(shift);
        _db.ShiftAssignments.Add(assignment);
        await _db.SaveChangesAsync();

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.DeleteAssignmentAsync(bandId, planId, shift.Id, assignment.Id, member2, CancellationToken.None));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
    }

    // ── UpdateAssignmentStatusAsync ───────────────────────────────────────────

    [Fact]
    public async Task UpdateAssignmentStatusAsync_OwnAssignment_UpdatesStatus()
    {
        var (_, bandId, planId) = await SeedPlanAsync();
        var memberId = await SeedAdditionalMemberAsync(bandId);
        var shift = new Shift { ShiftPlanId = planId, Name = "Shift", StartTime = new TimeOnly(10, 0), EndTime = new TimeOnly(12, 0), RequiredCount = 2 };
        var assignment = new ShiftAssignment { Shift = shift, MusicianId = memberId, Status = ShiftAssignmentStatus.Assigned };
        _db.Shifts.Add(shift);
        _db.ShiftAssignments.Add(assignment);
        await _db.SaveChangesAsync();

        var request = new UpdateShiftAssignmentStatusRequest(ShiftAssignmentStatus.Confirmed, "Will be there!");
        var result = await _sut.UpdateAssignmentStatusAsync(bandId, planId, shift.Id, assignment.Id, request, memberId, CancellationToken.None);

        Assert.Equal(ShiftAssignmentStatus.Confirmed, result.Status);
        Assert.Equal("Will be there!", result.Notes);
    }

    [Fact]
    public async Task UpdateAssignmentStatusAsync_AdminUpdatingOther_UpdatesStatus()
    {
        var (adminId, bandId, planId) = await SeedPlanAsync(MemberRole.Administrator);
        var memberId = await SeedAdditionalMemberAsync(bandId);
        var shift = new Shift { ShiftPlanId = planId, Name = "Shift", StartTime = new TimeOnly(10, 0), EndTime = new TimeOnly(12, 0), RequiredCount = 2 };
        var assignment = new ShiftAssignment { Shift = shift, MusicianId = memberId, Status = ShiftAssignmentStatus.Assigned };
        _db.Shifts.Add(shift);
        _db.ShiftAssignments.Add(assignment);
        await _db.SaveChangesAsync();

        var request = new UpdateShiftAssignmentStatusRequest(ShiftAssignmentStatus.Declined, "Unavailable");
        var result = await _sut.UpdateAssignmentStatusAsync(bandId, planId, shift.Id, assignment.Id, request, adminId, CancellationToken.None);

        Assert.Equal(ShiftAssignmentStatus.Declined, result.Status);
    }

    // ── GetMyShiftsAsync ──────────────────────────────────────────────────────

    [Fact]
    public async Task GetMyShiftsAsync_ReturnsOnlyUserShifts()
    {
        var (_, bandId, planId) = await SeedPlanAsync();
        var member1 = await SeedAdditionalMemberAsync(bandId);
        var member2 = await SeedAdditionalMemberAsync(bandId);
        var shift1 = new Shift { ShiftPlanId = planId, Name = "Shift 1", StartTime = new TimeOnly(10, 0), EndTime = new TimeOnly(12, 0), RequiredCount = 2 };
        var shift2 = new Shift { ShiftPlanId = planId, Name = "Shift 2", StartTime = new TimeOnly(14, 0), EndTime = new TimeOnly(16, 0), RequiredCount = 2 };
        var assignment1 = new ShiftAssignment { Shift = shift1, MusicianId = member1, Status = ShiftAssignmentStatus.Assigned };
        var assignment2 = new ShiftAssignment { Shift = shift2, MusicianId = member2, Status = ShiftAssignmentStatus.Assigned };
        _db.Shifts.AddRange(shift1, shift2);
        _db.ShiftAssignments.AddRange(assignment1, assignment2);
        await _db.SaveChangesAsync();

        var result = await _sut.GetMyShiftsAsync(bandId, member1, CancellationToken.None);

        Assert.Single(result);
        Assert.Equal("Shift 1", result[0].ShiftName);
    }
}
