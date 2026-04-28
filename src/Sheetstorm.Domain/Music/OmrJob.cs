namespace Sheetstorm.Domain.Music;

public enum OmrJobStatus
{
    Queued = 0,
    Running = 1,
    Done = 2,
    Failed = 3,
    Confirmed = 4,
}

public sealed class OmrJob
{
    public Guid Id { get; private set; } = Guid.NewGuid();
    public Guid BandId { get; private set; }
    public Guid CreatedById { get; private set; }
    public string OriginalFileName { get; private set; } = default!;
    public string InputBlobKey { get; private set; } = default!;
    public OmrJobStatus Status { get; private set; }
    public int Progress { get; private set; }
    public string? ErrorMessage { get; private set; }
    public string? DetectedPartsJson { get; private set; }
    public string? SuggestedTitle { get; private set; }
    public string? SuggestedComposer { get; private set; }
    public Guid? CreatedPieceId { get; private set; }
    public DateTimeOffset CreatedAt { get; private set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? StartedAt { get; private set; }
    public DateTimeOffset? CompletedAt { get; private set; }

    private OmrJob() { }

    public static OmrJob Create(Guid bandId, Guid createdById, string originalFileName, string inputBlobKey)
    {
        if (string.IsNullOrWhiteSpace(originalFileName)) throw new ArgumentException("Dateiname ist Pflicht");
        if (string.IsNullOrWhiteSpace(inputBlobKey)) throw new ArgumentException("BlobKey ist Pflicht");
        return new OmrJob
        {
            BandId = bandId,
            CreatedById = createdById,
            OriginalFileName = originalFileName,
            InputBlobKey = inputBlobKey,
            Status = OmrJobStatus.Queued,
        };
    }

    public void MarkRunning()
    {
        Status = OmrJobStatus.Running;
        StartedAt = DateTimeOffset.UtcNow;
        Progress = 5;
    }

    public void UpdateProgress(int percent) => Progress = Math.Clamp(percent, 0, 100);

    public void MarkDone(string detectedPartsJson, string? suggestedTitle, string? suggestedComposer)
    {
        Status = OmrJobStatus.Done;
        Progress = 100;
        DetectedPartsJson = detectedPartsJson;
        SuggestedTitle = suggestedTitle;
        SuggestedComposer = suggestedComposer;
        CompletedAt = DateTimeOffset.UtcNow;
    }

    public void MarkFailed(string error)
    {
        Status = OmrJobStatus.Failed;
        ErrorMessage = error;
        CompletedAt = DateTimeOffset.UtcNow;
    }

    public void MarkConfirmed(Guid pieceId)
    {
        Status = OmrJobStatus.Confirmed;
        CreatedPieceId = pieceId;
    }
}
