namespace Sheetstorm.Domain.Music;

public sealed class Piece
{
    public Guid Id { get; private set; } = Guid.NewGuid();
    public Guid BandId { get; private set; }
    public string Title { get; private set; } = default!;
    public string? Subtitle { get; private set; }
    public string? Composer { get; private set; }
    public string? Arranger { get; private set; }
    public string? Publisher { get; private set; }
    public string? PublisherNumber { get; private set; }
    public string? KeySignature { get; private set; }
    public string? TimeSignature { get; private set; }
    public int? Tempo { get; private set; }
    public int? DurationSeconds { get; private set; }
    public int? Difficulty { get; private set; }
    public string? Genre { get; private set; }
    public string? Tags { get; private set; }
    public string? Notes { get; private set; }
    public DateTimeOffset CreatedAt { get; private set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset UpdatedAt { get; private set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? DeletedAt { get; private set; }

    public ICollection<Part> Parts { get; private set; } = new List<Part>();

    private Piece() { }

    public static Piece Create(Guid bandId, string title)
    {
        if (bandId == Guid.Empty) throw new ArgumentException("BandId ist Pflicht", nameof(bandId));
        if (string.IsNullOrWhiteSpace(title)) throw new ArgumentException("Titel ist Pflicht", nameof(title));
        return new Piece { BandId = bandId, Title = title.Trim() };
    }

    public void UpdateMetadata(string title, string? subtitle, string? composer, string? arranger,
        string? publisher, string? publisherNumber, string? keySignature, string? timeSignature,
        int? tempo, int? durationSeconds, int? difficulty, string? genre, string? tags, string? notes)
    {
        if (string.IsNullOrWhiteSpace(title)) throw new ArgumentException("Titel ist Pflicht", nameof(title));
        if (difficulty is not null && (difficulty < 1 || difficulty > 6))
            throw new ArgumentOutOfRangeException(nameof(difficulty), "Schwierigkeit 1..6");
        Title = title.Trim();
        Subtitle = subtitle;
        Composer = composer;
        Arranger = arranger;
        Publisher = publisher;
        PublisherNumber = publisherNumber;
        KeySignature = keySignature;
        TimeSignature = timeSignature;
        Tempo = tempo;
        DurationSeconds = durationSeconds;
        Difficulty = difficulty;
        Genre = genre;
        Tags = tags;
        Notes = notes;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void SoftDelete() => DeletedAt = DateTimeOffset.UtcNow;
    public void Restore() => DeletedAt = null;
}
