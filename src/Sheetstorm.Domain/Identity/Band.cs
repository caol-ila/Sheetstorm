namespace Sheetstorm.Domain.Identity;

public sealed class Band
{
    public Guid Id { get; private set; } = Guid.NewGuid();
    public string Slug { get; private set; } = default!;
    public string Name { get; private set; } = default!;
    public string? Description { get; private set; }
    public string? LogoBlobKey { get; private set; }
    public string? City { get; private set; }
    public string? PostalCode { get; private set; }
    public string Country { get; private set; } = "DE";
    public string? AssociationName { get; private set; }
    public Guid OwnerId { get; private set; }
    public DateTimeOffset CreatedAt { get; private set; } = DateTimeOffset.UtcNow;

    public ICollection<Membership> Memberships { get; private set; } = new List<Membership>();
    public ICollection<BandInvitation> Invitations { get; private set; } = new List<BandInvitation>();
    public ICollection<BandJoinCode> JoinCodes { get; private set; } = new List<BandJoinCode>();

    private Band() { }

    public static Band Create(string name, string slug, Guid ownerId, string? description = null)
    {
        if (string.IsNullOrWhiteSpace(name)) throw new ArgumentException("Name ist Pflicht", nameof(name));
        if (string.IsNullOrWhiteSpace(slug)) throw new ArgumentException("Slug ist Pflicht", nameof(slug));

        return new Band
        {
            Name = name.Trim(),
            Slug = slug.Trim().ToLowerInvariant(),
            OwnerId = ownerId,
            Description = description,
        };
    }

    public void UpdateProfile(string name, string? description, string? city, string? postalCode, string? associationName)
    {
        if (string.IsNullOrWhiteSpace(name)) throw new ArgumentException("Name ist Pflicht", nameof(name));
        Name = name.Trim();
        Description = description;
        City = city;
        PostalCode = postalCode;
        AssociationName = associationName;
    }
}
