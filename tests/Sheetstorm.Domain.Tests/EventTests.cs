using FluentAssertions;
using Sheetstorm.Domain.Events;

namespace Sheetstorm.Domain.Tests;

public class EventTests
{
    [Fact]
    public void Create_RejectsEndBeforeStart() =>
        FluentActions.Invoking(() =>
        {
            var s = DateTimeOffset.UtcNow;
            return Event.Create(Guid.NewGuid(), EventType.Probe, "T", s, s.AddHours(-1), Guid.NewGuid());
        }).Should().Throw<ArgumentException>();

    [Fact]
    public void Cancel_FlagsTheEvent()
    {
        var ev = Event.Create(Guid.NewGuid(), EventType.Probe, "T", DateTimeOffset.UtcNow, DateTimeOffset.UtcNow.AddHours(2), Guid.NewGuid());
        ev.Cancelled.Should().BeFalse();
        ev.Cancel();
        ev.Cancelled.Should().BeTrue();
        ev.Reactivate();
        ev.Cancelled.Should().BeFalse();
    }
}

public class EventAttendanceTests
{
    [Fact]
    public void UpdateStatus_ChangesValueAndStamp()
    {
        var att = EventAttendance.Create(Guid.NewGuid(), Guid.NewGuid(), AttendanceStatus.Yes);
        att.UpdateStatus(AttendanceStatus.No, "krank");
        att.Status.Should().Be(AttendanceStatus.No);
        att.Reason.Should().Be("krank");
        att.RespondedAt.Should().BeCloseTo(DateTimeOffset.UtcNow, TimeSpan.FromSeconds(2));
    }
}

public class SetListTests
{
    [Fact]
    public void Create_RequiresName() =>
        FluentActions.Invoking(() => SetList.Create(Guid.NewGuid(), "", Guid.NewGuid()))
            .Should().Throw<ArgumentException>();
}

public class EventSyncSessionTests
{
    [Fact]
    public void Start_HasCounterZero()
    {
        var s = EventSyncSession.Start(Guid.NewGuid(), Guid.NewGuid());
        s.CurrentCounter.Should().Be(0);
        s.EndedAt.Should().BeNull();
    }

    [Fact]
    public void OpenPiece_RaisesCounter()
    {
        var s = EventSyncSession.Start(Guid.NewGuid(), Guid.NewGuid());
        s.OpenPiece(Guid.NewGuid(), "Marsch", 1);
        s.CurrentCounter.Should().Be(1);
        s.OpenPiece(Guid.NewGuid(), "Walzer", 2);
        s.CurrentCounter.Should().Be(2);
    }

    [Fact]
    public void OpenPiece_MonotonicallyIncreasing_IgnoresOlderCounter()
    {
        var s = EventSyncSession.Start(Guid.NewGuid(), Guid.NewGuid());
        s.OpenPiece(Guid.NewGuid(), "A", 5);
        s.OpenPiece(Guid.NewGuid(), "B", 3);
        s.CurrentCounter.Should().Be(5); // Replay-Schutz
    }

    [Fact]
    public void Stop_ClearsCurrentPieceAndEnds()
    {
        var s = EventSyncSession.Start(Guid.NewGuid(), Guid.NewGuid());
        s.OpenPiece(Guid.NewGuid(), "M", 1);
        s.Stop();
        s.EndedAt.Should().NotBeNull();
        s.CurrentPieceId.Should().BeNull();
    }

    [Fact]
    public void RegisterPublicKey_RequiresValue() =>
        FluentActions.Invoking(() =>
        {
            var s = EventSyncSession.Start(Guid.NewGuid(), Guid.NewGuid());
            s.RegisterPublicKey("");
        }).Should().Throw<ArgumentException>();
}

public class EventShiftTests
{
    [Fact]
    public void Create_TrimsTitleAndClampsCount()
    {
        var sh = EventShift.Create(Guid.NewGuid(), "  Theke  ", DateTimeOffset.UtcNow, DateTimeOffset.UtcNow.AddHours(2), -3);
        sh.Title.Should().Be("Theke");
        sh.RequiredCount.Should().Be(0);
    }
}
