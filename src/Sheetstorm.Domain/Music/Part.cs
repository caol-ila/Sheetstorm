using Sheetstorm.Domain.Identity;

namespace Sheetstorm.Domain.Music;

public sealed class Part
{
    public Guid Id { get; private set; } = Guid.NewGuid();
    public Guid PieceId { get; private set; }
    public Piece Piece { get; private set; } = default!;
    public Guid InstrumentId { get; private set; }
    public Instrument Instrument { get; private set; } = default!;
    public string? Transposition { get; private set; }
    public string? Register { get; private set; }
    public string DisplayName { get; private set; } = default!;
    public int OrderHint { get; private set; }
    public bool Retired { get; private set; }
    public DateTimeOffset CreatedAt { get; private set; } = DateTimeOffset.UtcNow;

    public ICollection<PartFile> Files { get; private set; } = new List<PartFile>();

    private Part() { }

    public static Part Create(Guid pieceId, Guid instrumentId, string displayName, string? transposition = null, string? register = null, int orderHint = 0)
    {
        if (string.IsNullOrWhiteSpace(displayName)) throw new ArgumentException("Anzeigename ist Pflicht", nameof(displayName));
        return new Part
        {
            PieceId = pieceId,
            InstrumentId = instrumentId,
            DisplayName = displayName.Trim(),
            Transposition = transposition,
            Register = register,
            OrderHint = orderHint,
        };
    }

    public void Retire() => Retired = true;
    public void Reactivate() => Retired = false;
}

public enum PartFileKind
{
    Pdf = 0,
    MusicXml = 1,
    Mp3 = 2,
    Midi = 3,
    PageImage = 4,
}

public sealed class PartFile
{
    public Guid Id { get; private set; } = Guid.NewGuid();
    public Guid PartId { get; private set; }
    public PartFileKind Kind { get; private set; }
    public string BlobKey { get; private set; } = default!;
    public string OriginalFileName { get; private set; } = default!;
    public int? Pages { get; private set; }
    public int? PageNumber { get; private set; }
    public long SizeBytes { get; private set; }
    public DateTimeOffset CreatedAt { get; private set; } = DateTimeOffset.UtcNow;

    private PartFile() { }

    public static PartFile Create(Guid partId, PartFileKind kind, string blobKey, string originalFileName, long sizeBytes, int? pages = null, int? pageNumber = null)
        => new()
        {
            PartId = partId,
            Kind = kind,
            BlobKey = blobKey,
            OriginalFileName = originalFileName,
            SizeBytes = sizeBytes,
            Pages = pages,
            PageNumber = pageNumber,
        };
}
