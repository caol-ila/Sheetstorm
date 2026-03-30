using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.JsonWebTokens;
using NSubstitute;
using NSubstitute.ExceptionExtensions;
using Sheetstorm.Api.Controllers;
using Sheetstorm.Domain.Auth;
using Sheetstorm.Domain.Enums;
using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Domain.Setlists;
using Sheetstorm.Infrastructure.Setlists;

namespace Sheetstorm.Tests.Setlists;

public class SetlistControllerTests
{
    private readonly ISetlistService _service;
    private readonly SetlistController _sut;
    private readonly Guid _musicianId = Guid.NewGuid();
    private readonly Guid _bandId = Guid.NewGuid();

    public SetlistControllerTests()
    {
        _service = Substitute.For<ISetlistService>();
        _sut = new SetlistController(_service);

        var claims = new ClaimsPrincipal(new ClaimsIdentity([
            new Claim(JwtRegisteredClaimNames.Sub, _musicianId.ToString())
        ]));
        _sut.ControllerContext = new ControllerContext
        {
            HttpContext = new DefaultHttpContext { User = claims }
        };
    }

    private static SetlistDto MakeSetlistDto(Guid id, string name = "Test Setlist") =>
        new(id, name, null, SetlistType.Concert, null, null, null, 0, null, DateTime.UtcNow);

    private static SetlistDetailDto MakeSetlistDetailDto(Guid id, string name = "Test Setlist") =>
        new(id, name, null, SetlistType.Concert, null, null, null, Array.Empty<SetlistEntryDto>(), null, DateTime.UtcNow);

    private static SetlistEntryDto MakeSetlistEntryDto(Guid id, int position = 0) =>
        new(id, position, null, null, null, true, "Placeholder", null, null, 120);

    // ── GetAll ───────────────────────────────────────────────────────────────────

    [Fact]
    public async Task GetAll_ReturnsOkWithList()
    {
        var setlists = new List<SetlistDto>
        {
            MakeSetlistDto(Guid.NewGuid(), "Setlist A"),
            MakeSetlistDto(Guid.NewGuid(), "Setlist B")
        };
        _service.GetAllAsync(_bandId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(setlists);

        var result = await _sut.GetAll(_bandId, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsAssignableFrom<IReadOnlyList<SetlistDto>>(ok.Value);
        Assert.Equal(2, returned.Count);
    }

    [Fact]
    public async Task GetAll_DelegatesCurrentUserIdToService()
    {
        _service.GetAllAsync(_bandId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(new List<SetlistDto>());

        await _sut.GetAll(_bandId, CancellationToken.None);

        await _service.Received(1).GetAllAsync(_bandId, _musicianId, Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task GetAll_ServiceThrowsDomainException_Propagates()
    {
        _service.GetAllAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("FORBIDDEN", "Band not found or no access.", 403));

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.GetAll(_bandId, CancellationToken.None));
    }

    // ── GetById ──────────────────────────────────────────────────────────────────

    [Fact]
    public async Task GetById_ReturnsOkWithDetail()
    {
        var setlistId = Guid.NewGuid();
        var dto = MakeSetlistDetailDto(setlistId, "Concert Setlist");
        _service.GetByIdAsync(_bandId, setlistId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(dto);

        var result = await _sut.GetById(_bandId, setlistId, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsType<SetlistDetailDto>(ok.Value);
        Assert.Equal(setlistId, returned.Id);
        Assert.Equal("Concert Setlist", returned.Name);
    }

    [Fact]
    public async Task GetById_PassesCorrectIdsToService()
    {
        var setlistId = Guid.NewGuid();
        _service.GetByIdAsync(_bandId, setlistId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(MakeSetlistDetailDto(setlistId));

        await _sut.GetById(_bandId, setlistId, CancellationToken.None);

        await _service.Received(1).GetByIdAsync(_bandId, setlistId, _musicianId, Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task GetById_NotFound_DomainExceptionPropagates()
    {
        _service.GetByIdAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("NOT_FOUND", "Setlist not found.", 404));

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.GetById(_bandId, Guid.NewGuid(), CancellationToken.None));
    }

    // ── Create ───────────────────────────────────────────────────────────────────

    [Fact]
    public async Task Create_ValidRequest_Returns201WithDetail()
    {
        var setlistId = Guid.NewGuid();
        var request = new CreateSetlistRequest("New Concert", null, SetlistType.Concert, null, null, null);
        var dto = MakeSetlistDetailDto(setlistId, "New Concert");
        _service.CreateAsync(_bandId, request, _musicianId, Arg.Any<CancellationToken>())
            .Returns(dto);

        var result = await _sut.Create(_bandId, request, CancellationToken.None);

        var created = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status201Created, created.StatusCode);
        var returned = Assert.IsType<SetlistDetailDto>(created.Value);
        Assert.Equal("New Concert", returned.Name);
    }

    [Fact]
    public async Task Create_InvalidModelState_ReturnsBadRequest()
    {
        _sut.ModelState.AddModelError("Name", "Required");
        var request = new CreateSetlistRequest("", null, SetlistType.Concert, null, null, null);

        var result = await _sut.Create(_bandId, request, CancellationToken.None);

        var bad = Assert.IsType<BadRequestObjectResult>(result);
        var err = Assert.IsType<ErrorResponse>(bad.Value);
        Assert.Equal("VALIDATION_ERROR", err.Error);
    }

    [Fact]
    public async Task Create_NotConductor_DomainExceptionPropagates()
    {
        var request = new CreateSetlistRequest("Test", null, SetlistType.Concert, null, null, null);
        _service.CreateAsync(Arg.Any<Guid>(), Arg.Any<CreateSetlistRequest>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("FORBIDDEN", "Forbidden.", 403));

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.Create(_bandId, request, CancellationToken.None));
    }

    // ── Update ───────────────────────────────────────────────────────────────────

    [Fact]
    public async Task Update_ValidRequest_ReturnsOkWithUpdatedDetail()
    {
        var setlistId = Guid.NewGuid();
        var request = new UpdateSetlistRequest("Updated Name", null, SetlistType.Rehearsal, null, null, null);
        var dto = MakeSetlistDetailDto(setlistId, "Updated Name");
        _service.UpdateAsync(_bandId, setlistId, request, _musicianId, Arg.Any<CancellationToken>())
            .Returns(dto);

        var result = await _sut.Update(_bandId, setlistId, request, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsType<SetlistDetailDto>(ok.Value);
        Assert.Equal("Updated Name", returned.Name);
    }

    [Fact]
    public async Task Update_InvalidModelState_ReturnsBadRequest()
    {
        _sut.ModelState.AddModelError("Name", "Required");
        var request = new UpdateSetlistRequest("", null, SetlistType.Concert, null, null, null);

        var result = await _sut.Update(_bandId, Guid.NewGuid(), request, CancellationToken.None);

        var bad = Assert.IsType<BadRequestObjectResult>(result);
        var err = Assert.IsType<ErrorResponse>(bad.Value);
        Assert.Equal("VALIDATION_ERROR", err.Error);
    }

    [Fact]
    public async Task Update_SetlistNotFound_DomainExceptionPropagates()
    {
        var request = new UpdateSetlistRequest("Test", null, SetlistType.Concert, null, null, null);
        _service.UpdateAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<UpdateSetlistRequest>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("NOT_FOUND", "Not found.", 404));

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.Update(_bandId, Guid.NewGuid(), request, CancellationToken.None));
    }

    // ── Delete ───────────────────────────────────────────────────────────────────

    [Fact]
    public async Task Delete_ValidRequest_Returns204NoContent()
    {
        var setlistId = Guid.NewGuid();
        _service.DeleteAsync(_bandId, setlistId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(Task.CompletedTask);

        var result = await _sut.Delete(_bandId, setlistId, CancellationToken.None);

        Assert.IsType<NoContentResult>(result);
    }

    [Fact]
    public async Task Delete_PassesCorrectIdsToService()
    {
        var setlistId = Guid.NewGuid();
        _service.DeleteAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .Returns(Task.CompletedTask);

        await _sut.Delete(_bandId, setlistId, CancellationToken.None);

        await _service.Received(1).DeleteAsync(_bandId, setlistId, _musicianId, Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task Delete_SetlistNotFound_DomainExceptionPropagates()
    {
        _service.DeleteAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("NOT_FOUND", "Not found.", 404));

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.Delete(_bandId, Guid.NewGuid(), CancellationToken.None));
    }

    // ── AddEntry ─────────────────────────────────────────────────────────────────

    [Fact]
    public async Task AddEntry_ValidRequest_Returns201WithEntry()
    {
        var setlistId = Guid.NewGuid();
        var entryId = Guid.NewGuid();
        var request = new AddSetlistEntryRequest(null, true, "Placeholder", null, null, 120);
        var dto = MakeSetlistEntryDto(entryId);
        _service.AddEntryAsync(_bandId, setlistId, request, _musicianId, Arg.Any<CancellationToken>())
            .Returns(dto);

        var result = await _sut.AddEntry(_bandId, setlistId, request, CancellationToken.None);

        var created = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status201Created, created.StatusCode);
        var returned = Assert.IsType<SetlistEntryDto>(created.Value);
        Assert.Equal(entryId, returned.Id);
    }

    [Fact]
    public async Task AddEntry_InvalidModelState_ReturnsBadRequest()
    {
        _sut.ModelState.AddModelError("PieceId", "Required");
        var request = new AddSetlistEntryRequest(null, false, null, null, null, null);

        var result = await _sut.AddEntry(_bandId, Guid.NewGuid(), request, CancellationToken.None);

        var bad = Assert.IsType<BadRequestObjectResult>(result);
        var err = Assert.IsType<ErrorResponse>(bad.Value);
        Assert.Equal("VALIDATION_ERROR", err.Error);
    }

    [Fact]
    public async Task AddEntry_ServiceThrowsValidationError_Propagates()
    {
        var request = new AddSetlistEntryRequest(null, true, null, null, null, null);
        _service.AddEntryAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<AddSetlistEntryRequest>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("VALIDATION_ERROR", "Placeholder title required.", 400));

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.AddEntry(_bandId, Guid.NewGuid(), request, CancellationToken.None));
    }

    // ── UpdateEntry ──────────────────────────────────────────────────────────────

    [Fact]
    public async Task UpdateEntry_ValidRequest_ReturnsOkWithUpdatedEntry()
    {
        var setlistId = Guid.NewGuid();
        var entryId = Guid.NewGuid();
        var request = new UpdateSetlistEntryRequest("Updated notes", 200);
        var dto = MakeSetlistEntryDto(entryId);
        _service.UpdateEntryAsync(_bandId, setlistId, entryId, request, _musicianId, Arg.Any<CancellationToken>())
            .Returns(dto);

        var result = await _sut.UpdateEntry(_bandId, setlistId, entryId, request, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsType<SetlistEntryDto>(ok.Value);
        Assert.Equal(entryId, returned.Id);
    }

    [Fact]
    public async Task UpdateEntry_InvalidModelState_ReturnsBadRequest()
    {
        _sut.ModelState.AddModelError("Notes", "Required");
        var request = new UpdateSetlistEntryRequest(null, null);

        var result = await _sut.UpdateEntry(_bandId, Guid.NewGuid(), Guid.NewGuid(), request, CancellationToken.None);

        var bad = Assert.IsType<BadRequestObjectResult>(result);
        var err = Assert.IsType<ErrorResponse>(bad.Value);
        Assert.Equal("VALIDATION_ERROR", err.Error);
    }

    [Fact]
    public async Task UpdateEntry_EntryNotFound_DomainExceptionPropagates()
    {
        var request = new UpdateSetlistEntryRequest("Notes", 100);
        _service.UpdateEntryAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<UpdateSetlistEntryRequest>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("NOT_FOUND", "Entry not found.", 404));

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.UpdateEntry(_bandId, Guid.NewGuid(), Guid.NewGuid(), request, CancellationToken.None));
    }

    // ── DeleteEntry ──────────────────────────────────────────────────────────────

    [Fact]
    public async Task DeleteEntry_ValidRequest_Returns204NoContent()
    {
        var setlistId = Guid.NewGuid();
        var entryId = Guid.NewGuid();
        _service.DeleteEntryAsync(_bandId, setlistId, entryId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(Task.CompletedTask);

        var result = await _sut.DeleteEntry(_bandId, setlistId, entryId, CancellationToken.None);

        Assert.IsType<NoContentResult>(result);
    }

    [Fact]
    public async Task DeleteEntry_PassesCorrectIdsToService()
    {
        var setlistId = Guid.NewGuid();
        var entryId = Guid.NewGuid();
        _service.DeleteEntryAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .Returns(Task.CompletedTask);

        await _sut.DeleteEntry(_bandId, setlistId, entryId, CancellationToken.None);

        await _service.Received(1).DeleteEntryAsync(_bandId, setlistId, entryId, _musicianId, Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task DeleteEntry_EntryNotFound_DomainExceptionPropagates()
    {
        _service.DeleteEntryAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("NOT_FOUND", "Not found.", 404));

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.DeleteEntry(_bandId, Guid.NewGuid(), Guid.NewGuid(), CancellationToken.None));
    }

    // ── ReorderEntries ───────────────────────────────────────────────────────────

    [Fact]
    public async Task ReorderEntries_ValidRequest_Returns204NoContent()
    {
        var setlistId = Guid.NewGuid();
        var request = new ReorderEntriesRequest(new[] { Guid.NewGuid(), Guid.NewGuid() });
        _service.ReorderEntriesAsync(_bandId, setlistId, request, _musicianId, Arg.Any<CancellationToken>())
            .Returns(Task.CompletedTask);

        var result = await _sut.ReorderEntries(_bandId, setlistId, request, CancellationToken.None);

        Assert.IsType<NoContentResult>(result);
    }

    [Fact]
    public async Task ReorderEntries_InvalidModelState_ReturnsBadRequest()
    {
        _sut.ModelState.AddModelError("EntryIds", "Required");
        var request = new ReorderEntriesRequest(Array.Empty<Guid>());

        var result = await _sut.ReorderEntries(_bandId, Guid.NewGuid(), request, CancellationToken.None);

        var bad = Assert.IsType<BadRequestObjectResult>(result);
        var err = Assert.IsType<ErrorResponse>(bad.Value);
        Assert.Equal("VALIDATION_ERROR", err.Error);
    }

    [Fact]
    public async Task ReorderEntries_ServiceThrowsValidationError_Propagates()
    {
        var request = new ReorderEntriesRequest(new[] { Guid.NewGuid() });
        _service.ReorderEntriesAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<ReorderEntriesRequest>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("VALIDATION_ERROR", "Invalid entry ID.", 400));

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.ReorderEntries(_bandId, Guid.NewGuid(), request, CancellationToken.None));
    }

    // ── Duplicate ────────────────────────────────────────────────────────────────

    [Fact]
    public async Task Duplicate_ValidRequest_Returns201WithDetail()
    {
        var setlistId = Guid.NewGuid();
        var duplicateId = Guid.NewGuid();
        var dto = MakeSetlistDetailDto(duplicateId, "Original (Copy)");
        _service.DuplicateAsync(_bandId, setlistId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(dto);

        var result = await _sut.Duplicate(_bandId, setlistId, CancellationToken.None);

        var created = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status201Created, created.StatusCode);
        var returned = Assert.IsType<SetlistDetailDto>(created.Value);
        Assert.Equal("Original (Copy)", returned.Name);
    }

    [Fact]
    public async Task Duplicate_PassesCorrectIdsToService()
    {
        var setlistId = Guid.NewGuid();
        _service.DuplicateAsync(_bandId, setlistId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(MakeSetlistDetailDto(Guid.NewGuid()));

        await _sut.Duplicate(_bandId, setlistId, CancellationToken.None);

        await _service.Received(1).DuplicateAsync(_bandId, setlistId, _musicianId, Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task Duplicate_SetlistNotFound_DomainExceptionPropagates()
    {
        _service.DuplicateAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("NOT_FOUND", "Not found.", 404));

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.Duplicate(_bandId, Guid.NewGuid(), CancellationToken.None));
    }

    // ── Band-scoped access ───────────────────────────────────────────────────────

    [Fact]
    public async Task BandScopedAccess_ServiceEnforcesIsolation_ControllerPropagatesException()
    {
        var foreignBandId = Guid.NewGuid();
        _service.GetAllAsync(foreignBandId, _musicianId, Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("FORBIDDEN", "Band not found or no access.", 403));

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.GetAll(foreignBandId, CancellationToken.None));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
        Assert.Equal(403, ex.StatusCode);
    }
}
