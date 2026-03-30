using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Domain.Polls;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Infrastructure.Polls;

public class PollService(AppDbContext db) : IPollService
{
    public async Task<IReadOnlyList<PollDto>> GetAllAsync(Guid bandId, Guid musicianId, CancellationToken ct)
    {
        await RequireMembershipAsync(bandId, musicianId, ct);

        var polls = await db.Set<Poll>()
            .Include(p => p.CreatedByMusician)
            .Include(p => p.Options)
            .ThenInclude(o => o.Votes)
            .Where(p => p.BandId == bandId)
            .OrderByDescending(p => p.CreatedAt)
            .ToListAsync(ct);

        return polls.Select(p => MapToDto(p, musicianId)).ToList();
    }

    public async Task<PollDetailDto> GetByIdAsync(Guid bandId, Guid pollId, Guid musicianId, CancellationToken ct)
    {
        await RequireMembershipAsync(bandId, musicianId, ct);

        var poll = await db.Set<Poll>()
            .Include(p => p.CreatedByMusician)
            .Include(p => p.Options)
            .ThenInclude(o => o.Votes)
            .FirstOrDefaultAsync(p => p.Id == pollId && p.BandId == bandId, ct)
            ?? throw new DomainException("NOT_FOUND", "Poll not found.", 404);

        var totalVotes = poll.Options.Sum(o => o.Votes.Count);
        var userHasVoted = poll.Options.Any(o => o.Votes.Any(v => v.MusicianId == musicianId));

        var options = poll.Options
            .OrderBy(o => o.Position)
            .Select(o => new PollOptionDto(
                o.Id,
                o.Text,
                o.Position,
                o.Votes.Count,
                totalVotes > 0 ? (double)o.Votes.Count / totalVotes * 100 : 0,
                o.Votes.Any(v => v.MusicianId == musicianId)
            ))
            .ToList();

        return new PollDetailDto(
            poll.Id,
            poll.Question,
            poll.IsAnonymous,
            poll.IsMultipleChoice,
            poll.ExpiresAt,
            poll.IsClosed,
            poll.CreatedByMusicianId,
            poll.CreatedByMusician.Name,
            options,
            totalVotes,
            userHasVoted,
            poll.CreatedAt
        );
    }

    public async Task<PollDetailDto> CreateAsync(Guid bandId, CreatePollRequest request, Guid musicianId, CancellationToken ct)
    {
        var membership = await RequireMembershipAsync(bandId, musicianId, ct);

        if (membership.Role != MemberRole.Administrator && 
            membership.Role != MemberRole.Conductor && 
            membership.Role != MemberRole.SectionLeader)
            throw new DomainException("FORBIDDEN", "Only admins, conductors, and section leaders can create polls.", 403);

        if (request.Options.Count < 2)
            throw new DomainException("VALIDATION_ERROR", "Poll must have at least 2 options.", 400);

        var poll = new Poll
        {
            BandId = bandId,
            CreatedByMusicianId = musicianId,
            Question = request.Question.Trim(),
            IsAnonymous = request.IsAnonymous,
            IsMultipleChoice = request.IsMultipleChoice,
            ExpiresAt = request.ExpiresAt
        };

        db.Set<Poll>().Add(poll);
        await db.SaveChangesAsync(ct);

        for (int i = 0; i < request.Options.Count; i++)
        {
            var option = new PollOption
            {
                PollId = poll.Id,
                Text = request.Options[i].Trim(),
                Position = i
            };
            db.Set<PollOption>().Add(option);
        }

        await db.SaveChangesAsync(ct);

        var musician = await db.Set<Musician>().FindAsync(new object[] { musicianId }, ct);

        var optionDtos = (await db.Set<PollOption>()
            .Where(o => o.PollId == poll.Id)
            .OrderBy(o => o.Position)
            .ToListAsync(ct))
            .Select(o => new PollOptionDto(o.Id, o.Text, o.Position, 0, 0, false))
            .ToList();

        return new PollDetailDto(
            poll.Id,
            poll.Question,
            poll.IsAnonymous,
            poll.IsMultipleChoice,
            poll.ExpiresAt,
            false,
            musicianId,
            musician!.Name,
            optionDtos,
            0,
            false,
            poll.CreatedAt
        );
    }

    public async Task DeleteAsync(Guid bandId, Guid pollId, Guid musicianId, CancellationToken ct)
    {
        var membership = await RequireMembershipAsync(bandId, musicianId, ct);

        var poll = await db.Set<Poll>()
            .FirstOrDefaultAsync(p => p.Id == pollId && p.BandId == bandId, ct)
            ?? throw new DomainException("NOT_FOUND", "Poll not found.", 404);

        if (poll.CreatedByMusicianId != musicianId && membership.Role != MemberRole.Administrator)
            throw new DomainException("FORBIDDEN", "You can only delete your own polls or be an admin.", 403);

        db.Set<Poll>().Remove(poll);
        await db.SaveChangesAsync(ct);
    }

    public async Task VoteAsync(Guid bandId, Guid pollId, VotePollRequest request, Guid musicianId, CancellationToken ct)
    {
        await RequireMembershipAsync(bandId, musicianId, ct);

        var poll = await db.Set<Poll>()
            .Include(p => p.Options)
            .ThenInclude(o => o.Votes)
            .FirstOrDefaultAsync(p => p.Id == pollId && p.BandId == bandId, ct)
            ?? throw new DomainException("NOT_FOUND", "Poll not found.", 404);

        if (poll.IsClosed)
            throw new DomainException("CONFLICT", "This poll is closed.", 409);

        if (poll.ExpiresAt.HasValue && poll.ExpiresAt.Value < DateTime.UtcNow)
            throw new DomainException("CONFLICT", "This poll has expired.", 409);

        if (!poll.IsMultipleChoice && request.OptionIds.Count > 1)
            throw new DomainException("VALIDATION_ERROR", "This poll only allows single choice.", 400);

        foreach (var optionId in request.OptionIds)
        {
            if (!poll.Options.Any(o => o.Id == optionId))
                throw new DomainException("VALIDATION_ERROR", "Invalid option ID.", 400);
        }

        var existingVotes = await db.Set<PollVote>()
            .Where(v => poll.Options.Select(o => o.Id).Contains(v.PollOptionId) && v.MusicianId == musicianId)
            .ToListAsync(ct);

        db.Set<PollVote>().RemoveRange(existingVotes);

        foreach (var optionId in request.OptionIds)
        {
            var vote = new PollVote
            {
                PollOptionId = optionId,
                MusicianId = musicianId
            };
            db.Set<PollVote>().Add(vote);
        }

        await db.SaveChangesAsync(ct);
    }

    public async Task CloseAsync(Guid bandId, Guid pollId, Guid musicianId, CancellationToken ct)
    {
        var membership = await RequireMembershipAsync(bandId, musicianId, ct);

        var poll = await db.Set<Poll>()
            .FirstOrDefaultAsync(p => p.Id == pollId && p.BandId == bandId, ct)
            ?? throw new DomainException("NOT_FOUND", "Poll not found.", 404);

        if (poll.CreatedByMusicianId != musicianId && 
            membership.Role != MemberRole.Administrator && 
            membership.Role != MemberRole.Conductor)
            throw new DomainException("FORBIDDEN", "Only poll creator, admins, or conductors can close polls.", 403);

        poll.IsClosed = true;
        await db.SaveChangesAsync(ct);
    }

    private async Task<Membership> RequireMembershipAsync(Guid bandId, Guid musicianId, CancellationToken ct)
    {
        var m = await db.Set<Membership>()
            .FirstOrDefaultAsync(m => m.BandId == bandId && m.MusicianId == musicianId && m.IsActive, ct);

        return m ?? throw new DomainException("BAND_NOT_FOUND", "Band not found or no access.", 404);
    }

    private static PollDto MapToDto(Poll poll, Guid currentMusicianId)
    {
        var totalVotes = poll.Options.Sum(o => o.Votes.Count);
        var userHasVoted = poll.Options.Any(o => o.Votes.Any(v => v.MusicianId == currentMusicianId));

        return new PollDto(
            poll.Id,
            poll.Question,
            poll.IsAnonymous,
            poll.IsMultipleChoice,
            poll.ExpiresAt,
            poll.IsClosed,
            poll.CreatedByMusicianId,
            poll.CreatedByMusician.Name,
            totalVotes,
            userHasVoted,
            poll.CreatedAt
        );
    }
}
