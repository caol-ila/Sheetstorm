using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Domain.Enums;
using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Domain.Tasks;
using Sheetstorm.Infrastructure.Persistence;
using Sheetstorm.Infrastructure.Tasks;

namespace Sheetstorm.Tests.Tasks;

public class TaskServiceTests : IDisposable
{
    private readonly AppDbContext _db;
    private readonly TaskService _sut;

    public TaskServiceTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        _db = new AppDbContext(options);
        _sut = new TaskService(_db);
    }

    public void Dispose()
    {
        _db.Dispose();
        GC.SuppressFinalize(this);
    }

    // ── Helpers ──────────────────────────────────────────────────────────────────

    private async Task<(Guid musicianId, Guid bandId)> SeedMembershipAsync(MemberRole role = MemberRole.Conductor)
    {
        var musician = new Musician { Email = $"m{Guid.NewGuid()}@test.com", Name = "Test User" };
        var band = new Band { Name = "Test Band" };
        var membership = new Membership { Musician = musician, Band = band, IsActive = true, Role = role };
        _db.Musicians.Add(musician);
        _db.Bands.Add(band);
        _db.Memberships.Add(membership);
        await _db.SaveChangesAsync();
        return (musician.Id, band.Id);
    }

    private async Task<Guid> SeedExtraMemberAsync(Guid bandId, MemberRole role = MemberRole.Musician)
    {
        var musician = new Musician { Email = $"m{Guid.NewGuid()}@test.com", Name = "Extra Member" };
        _db.Musicians.Add(musician);
        _db.Memberships.Add(new Membership { Musician = musician, BandId = bandId, IsActive = true, Role = role });
        await _db.SaveChangesAsync();
        return musician.Id;
    }

    private async Task<BandTask> SeedTaskAsync(Guid bandId, Guid creatorId, string title = "Test Task")
    {
        var task = new BandTask
        {
            BandId = bandId,
            CreatedByMusicianId = creatorId,
            Title = title,
            Status = BandTaskStatus.Open,
            Priority = TaskPriority.Medium
        };
        _db.Set<BandTask>().Add(task);
        await _db.SaveChangesAsync();
        return task;
    }

    // ── CreateTaskAsync ─────────────────────────────────────────────────────────

    [Fact]
    public async Task CreateTaskAsync_ValidRequest_CreatesTask()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.Conductor);
        var request = new CreateTaskRequest("Buy new music stands", "We need 10 new stands", null);

        var result = await _sut.CreateTaskAsync(bandId, request, musicianId, CancellationToken.None);

        Assert.Equal("Buy new music stands", result.Title);
        Assert.Equal("We need 10 new stands", result.Description);
        Assert.Equal(BandTaskStatus.Open, result.Status);
        Assert.Equal(TaskPriority.Medium, result.Priority);
        Assert.Equal(musicianId, result.CreatedByMusicianId);
        Assert.Equal(bandId, result.BandId);
    }

    [Fact]
    public async Task CreateTaskAsync_WithAssignees_AssignsMembers()
    {
        var (conductorId, bandId) = await SeedMembershipAsync(MemberRole.Conductor);
        var memberId = await SeedExtraMemberAsync(bandId);
        var request = new CreateTaskRequest("Prepare music", null, null, AssigneeIds: [memberId]);

        var result = await _sut.CreateTaskAsync(bandId, request, conductorId, CancellationToken.None);

        Assert.Single(result.Assignees);
        Assert.Equal(memberId, result.Assignees[0].MusicianId);
    }

    [Fact]
    public async Task CreateTaskAsync_NonMember_ThrowsForbidden()
    {
        var (_, bandId) = await SeedMembershipAsync();
        var outsiderId = Guid.NewGuid();
        var request = new CreateTaskRequest("Task", null, null);

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.CreateTaskAsync(bandId, request, outsiderId, CancellationToken.None));

        Assert.Equal(403, ex.StatusCode);
    }

    [Fact]
    public async Task CreateTaskAsync_MusicianRole_ThrowsForbidden()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.Musician);
        var request = new CreateTaskRequest("Task", null, null);

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.CreateTaskAsync(bandId, request, musicianId, CancellationToken.None));

        Assert.Equal(403, ex.StatusCode);
    }

    [Fact]
    public async Task CreateTaskAsync_WithDueDateAndPriority_SetsFields()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.Conductor);
        var dueDate = DateTime.UtcNow.AddDays(7);
        var request = new CreateTaskRequest("Task", null, dueDate, TaskPriority.High);

        var result = await _sut.CreateTaskAsync(bandId, request, musicianId, CancellationToken.None);

        Assert.Equal(dueDate, result.DueDate);
        Assert.Equal(TaskPriority.High, result.Priority);
    }

    // ── GetTasksAsync ───────────────────────────────────────────────────────────

    [Fact]
    public async Task GetTasksAsync_ReturnsBandTasks()
    {
        var (musicianId, bandId) = await SeedMembershipAsync();
        await SeedTaskAsync(bandId, musicianId, "Task A");
        await SeedTaskAsync(bandId, musicianId, "Task B");

        var result = await _sut.GetTasksAsync(bandId, musicianId, new TaskQueryParams(), CancellationToken.None);

        Assert.Equal(2, result.Count);
    }

    [Fact]
    public async Task GetTasksAsync_FilterByStatus_ReturnsMatchingTasks()
    {
        var (musicianId, bandId) = await SeedMembershipAsync();
        var openTask = await SeedTaskAsync(bandId, musicianId, "Open Task");
        var doneTask = await SeedTaskAsync(bandId, musicianId, "Done Task");
        doneTask.Status = BandTaskStatus.Done;
        await _db.SaveChangesAsync();

        var result = await _sut.GetTasksAsync(bandId, musicianId, new TaskQueryParams(Status: BandTaskStatus.Open), CancellationToken.None);

        Assert.Single(result);
        Assert.Equal("Open Task", result[0].Title);
    }

    [Fact]
    public async Task GetTasksAsync_FilterByAssignee_ReturnsAssignedTasks()
    {
        var (conductorId, bandId) = await SeedMembershipAsync(MemberRole.Conductor);
        var memberId = await SeedExtraMemberAsync(bandId);
        var assignedTask = await SeedTaskAsync(bandId, conductorId, "Assigned Task");
        await SeedTaskAsync(bandId, conductorId, "Unassigned Task");

        _db.Set<BandTaskAssignment>().Add(new BandTaskAssignment
        {
            BandTaskId = assignedTask.Id,
            MusicianId = memberId
        });
        await _db.SaveChangesAsync();

        var result = await _sut.GetTasksAsync(bandId, conductorId, new TaskQueryParams(AssigneeId: memberId), CancellationToken.None);

        Assert.Single(result);
        Assert.Equal("Assigned Task", result[0].Title);
    }

    [Fact]
    public async Task GetTasksAsync_SortByDueDate_ReturnsSortedAscending()
    {
        var (musicianId, bandId) = await SeedMembershipAsync();
        var t1 = await SeedTaskAsync(bandId, musicianId, "Late Task");
        t1.DueDate = DateTime.UtcNow.AddDays(10);
        var t2 = await SeedTaskAsync(bandId, musicianId, "Early Task");
        t2.DueDate = DateTime.UtcNow.AddDays(2);
        await _db.SaveChangesAsync();

        var result = await _sut.GetTasksAsync(bandId, musicianId, new TaskQueryParams(SortBy: "dueDate", SortDir: "asc"), CancellationToken.None);

        Assert.Equal("Early Task", result[0].Title);
    }

    [Fact]
    public async Task GetTasksAsync_NonMember_ThrowsForbidden()
    {
        var (_, bandId) = await SeedMembershipAsync();
        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.GetTasksAsync(bandId, Guid.NewGuid(), new TaskQueryParams(), CancellationToken.None));

        Assert.Equal(403, ex.StatusCode);
    }

    // ── GetTaskAsync ────────────────────────────────────────────────────────────

    [Fact]
    public async Task GetTaskAsync_ExistingTask_ReturnsDto()
    {
        var (musicianId, bandId) = await SeedMembershipAsync();
        var task = await SeedTaskAsync(bandId, musicianId, "My Task");

        var result = await _sut.GetTaskAsync(bandId, task.Id, musicianId, CancellationToken.None);

        Assert.Equal("My Task", result.Title);
        Assert.Equal(task.Id, result.Id);
    }

    [Fact]
    public async Task GetTaskAsync_WrongBand_ThrowsNotFound()
    {
        var (musicianId, bandId) = await SeedMembershipAsync();
        var task = await SeedTaskAsync(bandId, musicianId);
        var otherBand = new Band { Name = "Other Band" };
        _db.Bands.Add(otherBand);
        _db.Memberships.Add(new Membership { MusicianId = musicianId, Band = otherBand, IsActive = true, Role = MemberRole.Conductor });
        await _db.SaveChangesAsync();

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.GetTaskAsync(otherBand.Id, task.Id, musicianId, CancellationToken.None));

        Assert.Equal(404, ex.StatusCode);
    }

    [Fact]
    public async Task GetTaskAsync_NotFound_Throws()
    {
        var (musicianId, bandId) = await SeedMembershipAsync();

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.GetTaskAsync(bandId, Guid.NewGuid(), musicianId, CancellationToken.None));

        Assert.Equal(404, ex.StatusCode);
    }

    // ── UpdateTaskAsync ─────────────────────────────────────────────────────────

    [Fact]
    public async Task UpdateTaskAsync_ValidRequest_UpdatesTask()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.Conductor);
        var task = await SeedTaskAsync(bandId, musicianId);
        var request = new UpdateTaskRequest("Updated Title", "New desc", null, TaskPriority.High);

        var result = await _sut.UpdateTaskAsync(bandId, task.Id, request, musicianId, CancellationToken.None);

        Assert.Equal("Updated Title", result.Title);
        Assert.Equal("New desc", result.Description);
        Assert.Equal(TaskPriority.High, result.Priority);
    }

    [Fact]
    public async Task UpdateTaskAsync_RegularMember_ThrowsForbidden()
    {
        var (conductorId, bandId) = await SeedMembershipAsync(MemberRole.Conductor);
        var memberId = await SeedExtraMemberAsync(bandId, MemberRole.Musician);
        var task = await SeedTaskAsync(bandId, conductorId);
        var request = new UpdateTaskRequest("New Title", null, null);

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.UpdateTaskAsync(bandId, task.Id, request, memberId, CancellationToken.None));

        Assert.Equal(403, ex.StatusCode);
    }

    // ── DeleteTaskAsync ─────────────────────────────────────────────────────────

    [Fact]
    public async Task DeleteTaskAsync_ByCreator_DeletesTask()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.Conductor);
        var task = await SeedTaskAsync(bandId, musicianId);

        await _sut.DeleteTaskAsync(bandId, task.Id, musicianId, CancellationToken.None);

        var deleted = await _db.Set<BandTask>().FindAsync(task.Id);
        Assert.Null(deleted);
    }

    [Fact]
    public async Task DeleteTaskAsync_ByAdmin_DeletesTask()
    {
        var (conductorId, bandId) = await SeedMembershipAsync(MemberRole.Conductor);
        var adminId = await SeedExtraMemberAsync(bandId, MemberRole.Administrator);
        var task = await SeedTaskAsync(bandId, conductorId);

        await _sut.DeleteTaskAsync(bandId, task.Id, adminId, CancellationToken.None);

        var deleted = await _db.Set<BandTask>().FindAsync(task.Id);
        Assert.Null(deleted);
    }

    [Fact]
    public async Task DeleteTaskAsync_RegularMember_ThrowsForbidden()
    {
        var (conductorId, bandId) = await SeedMembershipAsync(MemberRole.Conductor);
        var memberId = await SeedExtraMemberAsync(bandId, MemberRole.Musician);
        var task = await SeedTaskAsync(bandId, conductorId);

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.DeleteTaskAsync(bandId, task.Id, memberId, CancellationToken.None));

        Assert.Equal(403, ex.StatusCode);
    }

    // ── UpdateStatusAsync ───────────────────────────────────────────────────────

    [Fact]
    public async Task UpdateStatusAsync_AssigneeCanChangeStatus()
    {
        var (conductorId, bandId) = await SeedMembershipAsync(MemberRole.Conductor);
        var memberId = await SeedExtraMemberAsync(bandId);
        var task = await SeedTaskAsync(bandId, conductorId);
        _db.Set<BandTaskAssignment>().Add(new BandTaskAssignment
        {
            BandTaskId = task.Id,
            MusicianId = memberId
        });
        await _db.SaveChangesAsync();

        var result = await _sut.UpdateStatusAsync(bandId, task.Id, new UpdateTaskStatusRequest(BandTaskStatus.InProgress), memberId, CancellationToken.None);

        Assert.Equal(BandTaskStatus.InProgress, result.Status);
    }

    [Fact]
    public async Task UpdateStatusAsync_CreatorCanChangeStatus()
    {
        var (conductorId, bandId) = await SeedMembershipAsync(MemberRole.Conductor);
        var task = await SeedTaskAsync(bandId, conductorId);

        var result = await _sut.UpdateStatusAsync(bandId, task.Id, new UpdateTaskStatusRequest(BandTaskStatus.Done), conductorId, CancellationToken.None);

        Assert.Equal(BandTaskStatus.Done, result.Status);
    }

    [Fact]
    public async Task UpdateStatusAsync_NonAssigneeNonCreator_ThrowsForbidden()
    {
        var (conductorId, bandId) = await SeedMembershipAsync(MemberRole.Conductor);
        var otherId = await SeedExtraMemberAsync(bandId, MemberRole.Musician);
        var task = await SeedTaskAsync(bandId, conductorId);

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.UpdateStatusAsync(bandId, task.Id, new UpdateTaskStatusRequest(BandTaskStatus.Done), otherId, CancellationToken.None));

        Assert.Equal(403, ex.StatusCode);
    }

    [Fact]
    public async Task UpdateStatusAsync_AllowsBackwardTransition()
    {
        var (conductorId, bandId) = await SeedMembershipAsync(MemberRole.Conductor);
        var task = await SeedTaskAsync(bandId, conductorId);
        task.Status = BandTaskStatus.Done;
        await _db.SaveChangesAsync();

        var result = await _sut.UpdateStatusAsync(bandId, task.Id, new UpdateTaskStatusRequest(BandTaskStatus.Open), conductorId, CancellationToken.None);

        Assert.Equal(BandTaskStatus.Open, result.Status);
    }

    // ── AssignTaskAsync ─────────────────────────────────────────────────────────

    [Fact]
    public async Task AssignTaskAsync_AddsMembersToTask()
    {
        var (conductorId, bandId) = await SeedMembershipAsync(MemberRole.Conductor);
        var memberId = await SeedExtraMemberAsync(bandId);
        var task = await SeedTaskAsync(bandId, conductorId);
        var request = new AssignTaskRequest([memberId]);

        var result = await _sut.AssignTaskAsync(bandId, task.Id, request, conductorId, CancellationToken.None);

        Assert.Single(result.Assignees);
        Assert.Equal(memberId, result.Assignees[0].MusicianId);
    }

    [Fact]
    public async Task AssignTaskAsync_ReplacesExistingAssignments()
    {
        var (conductorId, bandId) = await SeedMembershipAsync(MemberRole.Conductor);
        var member1 = await SeedExtraMemberAsync(bandId);
        var member2 = await SeedExtraMemberAsync(bandId);
        var task = await SeedTaskAsync(bandId, conductorId);
        _db.Set<BandTaskAssignment>().Add(new BandTaskAssignment { BandTaskId = task.Id, MusicianId = member1 });
        await _db.SaveChangesAsync();

        var result = await _sut.AssignTaskAsync(bandId, task.Id, new AssignTaskRequest([member2]), conductorId, CancellationToken.None);

        Assert.Single(result.Assignees);
        Assert.Equal(member2, result.Assignees[0].MusicianId);
    }

    [Fact]
    public async Task AssignTaskAsync_NonMemberOfBand_ThrowsBadRequest()
    {
        var (conductorId, bandId) = await SeedMembershipAsync(MemberRole.Conductor);
        var task = await SeedTaskAsync(bandId, conductorId);
        var outsiderId = Guid.NewGuid();

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.AssignTaskAsync(bandId, task.Id, new AssignTaskRequest([outsiderId]), conductorId, CancellationToken.None));

        Assert.Equal(400, ex.StatusCode);
    }
}
