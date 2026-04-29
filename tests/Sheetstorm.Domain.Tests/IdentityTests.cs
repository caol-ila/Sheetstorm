using FluentAssertions;
using Sheetstorm.Domain.Identity;

namespace Sheetstorm.Domain.Tests;

public class BandTests
{
    [Fact]
    public void Create_TrimsAndLowercasesSlug()
    {
        var b = Band.Create("  Musikverein Demo  ", "  DEMO  ", Guid.NewGuid());
        b.Name.Should().Be("Musikverein Demo");
        b.Slug.Should().Be("demo");
    }

    [Fact]
    public void Create_RejectsEmptyName() =>
        FluentActions.Invoking(() => Band.Create("", "demo", Guid.NewGuid()))
            .Should().Throw<ArgumentException>();

    [Fact]
    public void Create_RejectsEmptySlug() =>
        FluentActions.Invoking(() => Band.Create("Demo", "", Guid.NewGuid()))
            .Should().Throw<ArgumentException>();

    [Fact]
    public void UpdateProfile_PersistsChanges()
    {
        var b = Band.Create("Alt", "alt", Guid.NewGuid());
        b.UpdateProfile("Neu", "Beschreibung", "Stadt", "12345", "Verband-X");
        b.Name.Should().Be("Neu");
        b.Description.Should().Be("Beschreibung");
        b.City.Should().Be("Stadt");
        b.PostalCode.Should().Be("12345");
        b.AssociationName.Should().Be("Verband-X");
    }
}

public class MembershipTests
{
    [Fact]
    public void Create_DefaultsToActive_WithMitgliedRole()
    {
        var m = Membership.Create(Guid.NewGuid(), Guid.NewGuid(), BandRole.None);
        m.Status.Should().Be(MembershipStatus.Active);
        m.HasRole(BandRole.Mitglied).Should().BeTrue();
        m.JoinedAt.Should().NotBeNull();
    }

    [Fact]
    public void Pending_HasNoJoinedAt()
    {
        var m = Membership.Create(Guid.NewGuid(), Guid.NewGuid(), BandRole.Mitglied, MembershipStatus.Pending);
        m.JoinedAt.Should().BeNull();
    }

    [Fact]
    public void HasRole_ChecksFlags()
    {
        var m = Membership.Create(Guid.NewGuid(), Guid.NewGuid(), BandRole.Mitglied | BandRole.Dirigent | BandRole.Owner);
        m.HasRole(BandRole.Mitglied).Should().BeTrue();
        m.HasRole(BandRole.Dirigent).Should().BeTrue();
        m.HasRole(BandRole.Owner).Should().BeTrue();
        m.HasRole(BandRole.Admin).Should().BeFalse();
        m.HasRole(BandRole.Lehrer).Should().BeFalse();
    }

    [Fact]
    public void Grant_And_RevokeRole_WorkBitwise()
    {
        var m = Membership.Create(Guid.NewGuid(), Guid.NewGuid(), BandRole.Mitglied);
        m.GrantRole(BandRole.Dirigent | BandRole.Lehrer);
        m.HasRole(BandRole.Dirigent).Should().BeTrue();
        m.HasRole(BandRole.Lehrer).Should().BeTrue();
        m.RevokeRole(BandRole.Dirigent);
        m.HasRole(BandRole.Dirigent).Should().BeFalse();
        m.HasRole(BandRole.Lehrer).Should().BeTrue();
    }

    [Fact]
    public void Activate_FromPending_SetsJoinedAt()
    {
        var m = Membership.Create(Guid.NewGuid(), Guid.NewGuid(), BandRole.Mitglied, MembershipStatus.Pending);
        m.Activate();
        m.Status.Should().Be(MembershipStatus.Active);
        m.JoinedAt.Should().NotBeNull();
    }
}

public class BandJoinCodeTests
{
    [Fact]
    public void IsUsable_ChecksAllConstraints()
    {
        var jc = BandJoinCode.Create(Guid.NewGuid(), "hash", Guid.NewGuid(), maxUses: 2, expiresAt: DateTimeOffset.UtcNow.AddHours(1));
        jc.IsUsable(DateTimeOffset.UtcNow).Should().BeTrue();
    }

    [Fact]
    public void IsUsable_FalseIfExpired()
    {
        var jc = BandJoinCode.Create(Guid.NewGuid(), "h", Guid.NewGuid(), expiresAt: DateTimeOffset.UtcNow.AddHours(-1));
        jc.IsUsable(DateTimeOffset.UtcNow).Should().BeFalse();
    }

    [Fact]
    public void RegisterUse_DeactivatesAtMaxUses()
    {
        var jc = BandJoinCode.Create(Guid.NewGuid(), "h", Guid.NewGuid(), maxUses: 2);
        jc.RegisterUse();
        jc.Active.Should().BeTrue();
        jc.RegisterUse();
        jc.Active.Should().BeFalse();
        jc.IsUsable(DateTimeOffset.UtcNow).Should().BeFalse();
    }
}

public class BandInvitationTests
{
    [Fact]
    public void Create_NormalizesEmail()
    {
        var inv = BandInvitation.Create(Guid.NewGuid(), "  Foo@Example.TEST ", "h", DateTimeOffset.UtcNow.AddDays(7), BandRole.Mitglied, Guid.NewGuid());
        inv.Email.Should().Be("foo@example.test");
    }

    [Fact]
    public void IsValidNow_FalseAfterAccept()
    {
        var inv = BandInvitation.Create(Guid.NewGuid(), "x@y.de", "h", DateTimeOffset.UtcNow.AddDays(7), BandRole.Mitglied, Guid.NewGuid());
        inv.IsValidNow(DateTimeOffset.UtcNow).Should().BeTrue();
        inv.MarkAccepted(Guid.NewGuid(), DateTimeOffset.UtcNow);
        inv.IsValidNow(DateTimeOffset.UtcNow).Should().BeFalse();
    }
}
