using FluentAssertions;
using Sheetstorm.Domain.Music;

namespace Sheetstorm.Domain.Tests;

public class PieceTests
{
    [Fact]
    public void Create_RejectsEmptyTitle() =>
        FluentActions.Invoking(() => Piece.Create(Guid.NewGuid(), ""))
            .Should().Throw<ArgumentException>();

    [Fact]
    public void Create_RejectsEmptyBandId() =>
        FluentActions.Invoking(() => Piece.Create(Guid.Empty, "Titel"))
            .Should().Throw<ArgumentException>();

    [Fact]
    public void UpdateMetadata_ValidatesDifficultyRange() =>
        FluentActions.Invoking(() =>
        {
            var p = Piece.Create(Guid.NewGuid(), "T");
            p.UpdateMetadata("T", null, null, null, null, null, null, null, null, null, 7, null, null, null);
        }).Should().Throw<ArgumentOutOfRangeException>();

    [Fact]
    public void SoftDelete_SetsDeletedAt()
    {
        var p = Piece.Create(Guid.NewGuid(), "T");
        p.DeletedAt.Should().BeNull();
        p.SoftDelete();
        p.DeletedAt.Should().NotBeNull();
        p.Restore();
        p.DeletedAt.Should().BeNull();
    }
}

public class PartTests
{
    [Fact]
    public void Create_TrimsDisplayName()
    {
        var part = Part.Create(Guid.NewGuid(), Guid.NewGuid(), "  Klarinette  ", "B");
        part.DisplayName.Should().Be("Klarinette");
        part.Transposition.Should().Be("B");
    }

    [Fact]
    public void Retire_AndReactivate_WorkAsExpected()
    {
        var part = Part.Create(Guid.NewGuid(), Guid.NewGuid(), "X");
        part.Retired.Should().BeFalse();
        part.Retire();
        part.Retired.Should().BeTrue();
        part.Reactivate();
        part.Retired.Should().BeFalse();
    }
}

public class OmrJobTests
{
    [Fact]
    public void Create_StartsAsQueued()
    {
        var j = OmrJob.Create(Guid.NewGuid(), Guid.NewGuid(), "f.pdf", "blob/x");
        j.Status.Should().Be(OmrJobStatus.Queued);
        j.Progress.Should().Be(0);
        j.StartedAt.Should().BeNull();
    }

    [Fact]
    public void StateMachine_RunningDoneConfirmed()
    {
        var j = OmrJob.Create(Guid.NewGuid(), Guid.NewGuid(), "f.pdf", "blob/x");
        j.MarkRunning();
        j.Status.Should().Be(OmrJobStatus.Running);
        j.StartedAt.Should().NotBeNull();
        j.UpdateProgress(50);
        j.Progress.Should().Be(50);
        j.MarkDone("[]", "Titel", "Komp");
        j.Status.Should().Be(OmrJobStatus.Done);
        j.Progress.Should().Be(100);
        j.SuggestedTitle.Should().Be("Titel");
        var pieceId = Guid.NewGuid();
        j.MarkConfirmed(pieceId);
        j.Status.Should().Be(OmrJobStatus.Confirmed);
        j.CreatedPieceId.Should().Be(pieceId);
    }

    [Fact]
    public void MarkFailed_SetsError()
    {
        var j = OmrJob.Create(Guid.NewGuid(), Guid.NewGuid(), "f.pdf", "blob/x");
        j.MarkFailed("oops");
        j.Status.Should().Be(OmrJobStatus.Failed);
        j.ErrorMessage.Should().Be("oops");
    }

    [Fact]
    public void UpdateProgress_ClampsRange()
    {
        var j = OmrJob.Create(Guid.NewGuid(), Guid.NewGuid(), "f.pdf", "blob/x");
        j.UpdateProgress(-10);
        j.Progress.Should().Be(0);
        j.UpdateProgress(150);
        j.Progress.Should().Be(100);
    }
}

public class OfflineWishTests
{
    [Fact]
    public void Create_PopulatesFields()
    {
        var u = Guid.NewGuid();
        var p = Guid.NewGuid();
        var w = OfflineWish.Create(u, p);
        w.UserId.Should().Be(u);
        w.PieceId.Should().Be(p);
        w.MarkedAt.Should().BeCloseTo(DateTimeOffset.UtcNow, TimeSpan.FromSeconds(2));
    }
}

public class AnnotationTests
{
    [Fact]
    public void Create_StartsAtVersion1()
    {
        var a = Annotation.Create(Guid.NewGuid(), Guid.NewGuid(), 1, "{}");
        a.Version.Should().Be(1);
        a.Page.Should().Be(1);
    }

    [Fact]
    public void Update_BumpsVersion()
    {
        var a = Annotation.Create(Guid.NewGuid(), Guid.NewGuid(), 1, "{}");
        a.Update("[1,2,3]");
        a.Version.Should().Be(2);
        a.LayerJson.Should().Be("[1,2,3]");
    }
}
