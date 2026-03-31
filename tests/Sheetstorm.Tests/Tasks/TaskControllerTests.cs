using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.JsonWebTokens;
using NSubstitute;
using NSubstitute.ExceptionExtensions;
using Sheetstorm.Api.Controllers;
using Sheetstorm.Domain.Enums;
using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Domain.Tasks;
using Sheetstorm.Infrastructure.Tasks;

namespace Sheetstorm.Tests.Tasks;

public class TaskControllerTests
{
    private readonly ITaskService _service;
    private readonly TaskController _sut;
    private readonly Guid _musicianId = Guid.NewGuid();
    private readonly Guid _bandId = Guid.NewGuid();

    public TaskControllerTests()
    {
        _service = Substitute.For<ITaskService>();
        _sut = new TaskController(_service);

        var claims = new ClaimsPrincipal(new ClaimsIdentity([
            new Claim(JwtRegisteredClaimNames.Sub, _musicianId.ToString())
        ]));
        _sut.ControllerContext = new ControllerContext
        {
            HttpContext = new DefaultHttpContext { User = claims }
        };
    }

    private BandTaskDto MakeTaskDto(Guid? id = null, string title = "Test Task") =>
        new(id ?? Guid.NewGuid(), _bandId, title, null, BandTaskStatus.Open, TaskPriority.Medium,
            null, null, _musicianId, "Creator", [], DateTime.UtcNow, DateTime.UtcNow);

    // ── GetTasks ─────────────────────────────────────────────────────────────────

    [Fact]
    public async Task GetTasks_ReturnsOkWithList()
    {
        var tasks = new List<BandTaskDto> { MakeTaskDto(title: "Task A"), MakeTaskDto(title: "Task B") };
        _service.GetTasksAsync(_bandId, _musicianId, Arg.Any<TaskQueryParams>(), Arg.Any<CancellationToken>())
            .Returns(tasks);

        var result = await _sut.GetTasks(_bandId, null, null, null, null, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsAssignableFrom<IReadOnlyList<BandTaskDto>>(ok.Value);
        Assert.Equal(2, returned.Count);
    }

    [Fact]
    public async Task GetTasks_PassesQueryParamsToService()
    {
        _service.GetTasksAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<TaskQueryParams>(), Arg.Any<CancellationToken>())
            .Returns(new List<BandTaskDto>());

        await _sut.GetTasks(_bandId, BandTaskStatus.Open, null, "dueDate", "desc", CancellationToken.None);

        await _service.Received(1).GetTasksAsync(
            _bandId,
            _musicianId,
            Arg.Is<TaskQueryParams>(q => q.Status == BandTaskStatus.Open && q.SortBy == "dueDate" && q.SortDir == "desc"),
            Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task GetTasks_ServiceThrowsDomainException_Propagates()
    {
        _service.GetTasksAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<TaskQueryParams>(), Arg.Any<CancellationToken>())
            .Throws(new DomainException("FORBIDDEN", "Not a member.", 403));

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.GetTasks(_bandId, null, null, null, null, CancellationToken.None));
    }

    // ── GetTask ──────────────────────────────────────────────────────────────────

    [Fact]
    public async Task GetTask_ReturnsOkWithDto()
    {
        var taskId = Guid.NewGuid();
        var dto = MakeTaskDto(taskId, "My Task");
        _service.GetTaskAsync(_bandId, taskId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(dto);

        var result = await _sut.GetTask(_bandId, taskId, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsType<BandTaskDto>(ok.Value);
        Assert.Equal("My Task", returned.Title);
    }

    [Fact]
    public async Task GetTask_NotFound_Propagates()
    {
        _service.GetTaskAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .Throws(new DomainException("NOT_FOUND", "Task not found.", 404));

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.GetTask(_bandId, Guid.NewGuid(), CancellationToken.None));
    }

    // ── CreateTask ───────────────────────────────────────────────────────────────

    [Fact]
    public async Task CreateTask_ValidRequest_Returns201()
    {
        var taskId = Guid.NewGuid();
        var request = new CreateTaskRequest("New Task", null, null);
        var dto = MakeTaskDto(taskId, "New Task");
        _service.CreateTaskAsync(_bandId, request, _musicianId, Arg.Any<CancellationToken>())
            .Returns(dto);

        var result = await _sut.CreateTask(_bandId, request, CancellationToken.None);

        var created = Assert.IsType<ObjectResult>(result);
        Assert.Equal(201, created.StatusCode);
    }

    [Fact]
    public async Task CreateTask_InvalidModel_ReturnsBadRequest()
    {
        _sut.ModelState.AddModelError("Title", "Required");
        var request = new CreateTaskRequest("", null, null);

        var result = await _sut.CreateTask(_bandId, request, CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result);
    }

    [Fact]
    public async Task CreateTask_ServiceThrowsForbidden_Propagates()
    {
        var request = new CreateTaskRequest("Task", null, null);
        _service.CreateTaskAsync(Arg.Any<Guid>(), Arg.Any<CreateTaskRequest>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .Throws(new DomainException("FORBIDDEN", "Not authorized.", 403));

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.CreateTask(_bandId, request, CancellationToken.None));
    }

    // ── UpdateTask ───────────────────────────────────────────────────────────────

    [Fact]
    public async Task UpdateTask_ValidRequest_ReturnsOk()
    {
        var taskId = Guid.NewGuid();
        var request = new UpdateTaskRequest("Updated Title", null, null);
        var dto = MakeTaskDto(taskId, "Updated Title");
        _service.UpdateTaskAsync(_bandId, taskId, request, _musicianId, Arg.Any<CancellationToken>())
            .Returns(dto);

        var result = await _sut.UpdateTask(_bandId, taskId, request, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        Assert.IsType<BandTaskDto>(ok.Value);
    }

    [Fact]
    public async Task UpdateTask_InvalidModel_ReturnsBadRequest()
    {
        _sut.ModelState.AddModelError("Title", "Required");
        var request = new UpdateTaskRequest("", null, null);

        var result = await _sut.UpdateTask(_bandId, Guid.NewGuid(), request, CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result);
    }

    // ── DeleteTask ───────────────────────────────────────────────────────────────

    [Fact]
    public async Task DeleteTask_ReturnsNoContent()
    {
        var taskId = Guid.NewGuid();
        _service.DeleteTaskAsync(_bandId, taskId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(Task.CompletedTask);

        var result = await _sut.DeleteTask(_bandId, taskId, CancellationToken.None);

        Assert.IsType<NoContentResult>(result);
    }

    [Fact]
    public async Task DeleteTask_NotFound_Propagates()
    {
        _service.DeleteTaskAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .Throws(new DomainException("NOT_FOUND", "Task not found.", 404));

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.DeleteTask(_bandId, Guid.NewGuid(), CancellationToken.None));
    }

    // ── UpdateStatus ─────────────────────────────────────────────────────────────

    [Fact]
    public async Task UpdateStatus_ValidRequest_ReturnsOk()
    {
        var taskId = Guid.NewGuid();
        var request = new UpdateTaskStatusRequest(BandTaskStatus.Done);
        var dto = MakeTaskDto(taskId) with { Status = BandTaskStatus.Done };
        _service.UpdateStatusAsync(_bandId, taskId, request, _musicianId, Arg.Any<CancellationToken>())
            .Returns(dto);

        var result = await _sut.UpdateStatus(_bandId, taskId, request, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsType<BandTaskDto>(ok.Value);
        Assert.Equal(BandTaskStatus.Done, returned.Status);
    }

    // ── AssignTask ───────────────────────────────────────────────────────────────

    [Fact]
    public async Task AssignTask_ValidRequest_ReturnsOk()
    {
        var taskId = Guid.NewGuid();
        var assigneeId = Guid.NewGuid();
        var request = new AssignTaskRequest([assigneeId]);
        var dto = MakeTaskDto(taskId) with
        {
            Assignees = new List<TaskAssigneeDto> { new(assigneeId, "Member") }
        };
        _service.AssignTaskAsync(_bandId, taskId, request, _musicianId, Arg.Any<CancellationToken>())
            .Returns(dto);

        var result = await _sut.AssignTask(_bandId, taskId, request, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsType<BandTaskDto>(ok.Value);
        Assert.Single(returned.Assignees);
    }
}
