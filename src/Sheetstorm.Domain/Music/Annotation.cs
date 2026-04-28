namespace Sheetstorm.Domain.Music;

/// <summary>
/// Persönliche Annotationen eines Musikers an einer Stimme (pro Seite).
/// Datenformat: JSON mit Pen-Strokes, Text-Boxen, Stempeln.
/// </summary>
public sealed class Annotation
{
    public Guid Id { get; private set; } = Guid.NewGuid();
    public Guid PartId { get; private set; }
    public Guid UserId { get; private set; }
    public int Page { get; private set; }
    public string LayerJson { get; private set; } = "{}";
    public DateTimeOffset UpdatedAt { get; private set; } = DateTimeOffset.UtcNow;
    public long Version { get; private set; } = 1;

    private Annotation() { }

    public static Annotation Create(Guid partId, Guid userId, int page, string layerJson)
        => new() { PartId = partId, UserId = userId, Page = page, LayerJson = layerJson };

    public void Update(string layerJson)
    {
        LayerJson = layerJson;
        UpdatedAt = DateTimeOffset.UtcNow;
        Version++;
    }
}
