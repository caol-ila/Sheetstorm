using System.ComponentModel.DataAnnotations;

namespace Sheetstorm.Domain.Polls;

// ── Requests ──────────────────────────────────────────────────
public record CreatePollRequest(
    [Required][StringLength(250, MinimumLength = 1)] string Question,
    [Required][MinLength(2)] IReadOnlyList<string> Options,
    bool IsAnonymous = false,
    bool IsMultipleChoice = false,
    DateTime? ExpiresAt = null
);

public record VotePollRequest(
    [Required][MinLength(1)] IReadOnlyList<Guid> OptionIds
);

// ── Responses ──────────────────────────────────────────────────
public record PollDto(
    Guid Id,
    string Question,
    bool IsAnonymous,
    bool IsMultipleChoice,
    DateTime? ExpiresAt,
    bool IsClosed,
    Guid CreatedByMusicianId,
    string CreatedByMusicianName,
    int TotalVotes,
    bool UserHasVoted,
    DateTime CreatedAt
);

public record PollDetailDto(
    Guid Id,
    string Question,
    bool IsAnonymous,
    bool IsMultipleChoice,
    DateTime? ExpiresAt,
    bool IsClosed,
    Guid CreatedByMusicianId,
    string CreatedByMusicianName,
    IReadOnlyList<PollOptionDto> Options,
    int TotalVotes,
    bool UserHasVoted,
    DateTime CreatedAt
);

public record PollOptionDto(
    Guid Id,
    string Text,
    int Position,
    int VoteCount,
    double VotePercentage,
    bool UserVoted
);
