using System.Text;
using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Events;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Web.Application;

public sealed record PollListItem(Guid Id, PollKind Kind, string Title, DateTimeOffset CreatedAt, DateTimeOffset? ClosesAt, bool IsClosed, int OptionCount, int ResponseCount);

public sealed record PollDetailView(
    Guid Id,
    PollKind Kind,
    string Title,
    string? Description,
    DateTimeOffset CreatedAt,
    DateTimeOffset? ClosesAt,
    bool IsClosed,
    bool AllowMultiple,
    bool AnonymousResults,
    Guid CreatedByUserId,
    IReadOnlyList<PollOptionView> Options,
    IReadOnlyList<PollResponseView> Responses);

public sealed record PollOptionView(Guid Id, string Label, DateTimeOffset? AsDateTime, int Order, int Yes, int Maybe, int No);
public sealed record PollResponseView(Guid Id, Guid UserId, string? UserDisplayName, Guid? OptionId, PollAnswer Answer, string? FreeTextAnswer, string? Size, int? Quantity, DateTimeOffset RespondedAt);

public sealed class PollService(SheetstormDbContext db)
{
    public async Task<List<PollListItem>> GetForEventAsync(Guid eventId, CancellationToken ct = default) =>
        await db.EventPolls.Where(p => p.EventId == eventId).OrderByDescending(p => p.CreatedAt)
            .Select(p => new PollListItem(p.Id, p.Kind, p.Title, p.CreatedAt, p.ClosesAt,
                p.ClosesAt.HasValue && p.ClosesAt < DateTimeOffset.UtcNow,
                p.Options.Count, p.Responses.Select(r => r.UserId).Distinct().Count()))
            .ToListAsync(ct);

    public async Task<List<PollListItem>> GetForBandAsync(Guid bandId, CancellationToken ct = default) =>
        await db.EventPolls.Where(p => p.BandId == bandId && p.EventId == null).OrderByDescending(p => p.CreatedAt)
            .Select(p => new PollListItem(p.Id, p.Kind, p.Title, p.CreatedAt, p.ClosesAt,
                p.ClosesAt.HasValue && p.ClosesAt < DateTimeOffset.UtcNow,
                p.Options.Count, p.Responses.Select(r => r.UserId).Distinct().Count()))
            .ToListAsync(ct);

    public async Task<EventPoll> CreateAsync(PollKind kind, string title, Guid createdByUserId, Guid? eventId, Guid? bandId, string? description, DateTimeOffset? closesAt, bool allowMultiple, bool anonymousResults, IEnumerable<string> initialOptions, CancellationToken ct = default)
    {
        var poll = EventPoll.Create(kind, title, createdByUserId, eventId, bandId, description, closesAt, allowMultiple, anonymousResults);
        db.EventPolls.Add(poll);
        await db.SaveChangesAsync(ct);

        var i = 0;
        foreach (var label in initialOptions.Where(s => !string.IsNullOrWhiteSpace(s)))
        {
            DateTimeOffset? dt = null;
            if (kind == PollKind.DateFinder && DateTimeOffset.TryParse(label, out var parsed)) dt = parsed;
            db.PollOptions.Add(PollOption.Create(poll.Id, label.Trim(), i++, dt));
        }
        await db.SaveChangesAsync(ct);
        return poll;
    }

    public async Task<PollDetailView?> GetAsync(Guid pollId, Guid? currentUserId, CancellationToken ct = default)
    {
        var poll = await db.EventPolls.Include(p => p.Options).Include(p => p.Responses).FirstOrDefaultAsync(p => p.Id == pollId, ct);
        if (poll is null) return null;

        var userIds = poll.Responses.Select(r => r.UserId).Distinct().ToList();
        var userMap = await db.Users.Where(u => userIds.Contains(u.Id))
            .Select(u => new { u.Id, u.DisplayName }).ToDictionaryAsync(u => u.Id, u => u.DisplayName, ct);

        var optionViews = poll.Options.OrderBy(o => o.Order).Select(o => new PollOptionView(
            o.Id, o.Label, o.AsDateTime, o.Order,
            poll.Responses.Count(r => r.OptionId == o.Id && r.Answer == PollAnswer.Yes),
            poll.Responses.Count(r => r.OptionId == o.Id && r.Answer == PollAnswer.Maybe),
            poll.Responses.Count(r => r.OptionId == o.Id && r.Answer == PollAnswer.No)
        )).ToList();

        // Anonyme Polls: einzelne Antworten verbergen, nur Aggregate. Owner sieht trotzdem alles.
        var hideIndividual = poll.AnonymousResults && currentUserId != poll.CreatedByUserId;
        var responses = hideIndividual
            ? new List<PollResponseView>()
            : poll.Responses.Select(r => new PollResponseView(
                r.Id, r.UserId, userMap.GetValueOrDefault(r.UserId),
                r.OptionId, r.Answer, r.FreeTextAnswer, r.Size, r.Quantity, r.RespondedAt)).ToList();

        return new PollDetailView(poll.Id, poll.Kind, poll.Title, poll.Description, poll.CreatedAt, poll.ClosesAt,
            poll.IsClosed, poll.AllowMultiple, poll.AnonymousResults, poll.CreatedByUserId, optionViews, responses);
    }

    public async Task RespondAsync(Guid pollId, Guid userId, Guid? optionId, PollAnswer answer = PollAnswer.Yes, string? freeTextAnswer = null, string? size = null, int? quantity = null, CancellationToken ct = default)
    {
        var poll = await db.EventPolls.Include(p => p.Responses).FirstOrDefaultAsync(p => p.Id == pollId, ct)
            ?? throw new InvalidOperationException("Poll nicht gefunden");
        if (poll.IsClosed) throw new InvalidOperationException("Poll ist geschlossen");

        // Vote ohne Mehrfach-Auswahl: alte Antwort des Users ueberschreiben
        if (poll.Kind == PollKind.Vote && !poll.AllowMultiple)
        {
            var existing = poll.Responses.FirstOrDefault(r => r.UserId == userId);
            if (existing is not null)
            {
                if (existing.OptionId == optionId)
                {
                    existing.Update(answer, freeTextAnswer, size, quantity);
                }
                else
                {
                    db.PollResponses.Remove(existing);
                    db.PollResponses.Add(PollResponse.Create(pollId, userId, optionId, answer, freeTextAnswer, size, quantity));
                }
                await db.SaveChangesAsync(ct);
                return;
            }
        }

        // DateFinder: pro Option max 1 Antwort des Users (Yes/Maybe/No durchschalten)
        if (poll.Kind == PollKind.DateFinder)
        {
            var existing = poll.Responses.FirstOrDefault(r => r.UserId == userId && r.OptionId == optionId);
            if (existing is not null)
            {
                existing.Update(answer, freeTextAnswer, size, quantity);
                await db.SaveChangesAsync(ct);
                return;
            }
        }

        // DemandSurvey: pro User max 1 Antwort
        if (poll.Kind == PollKind.DemandSurvey)
        {
            var existing = poll.Responses.FirstOrDefault(r => r.UserId == userId);
            if (existing is not null)
            {
                existing.Update(answer, freeTextAnswer, size, quantity);
                await db.SaveChangesAsync(ct);
                return;
            }
        }

        db.PollResponses.Add(PollResponse.Create(pollId, userId, optionId, answer, freeTextAnswer, size, quantity));
        await db.SaveChangesAsync(ct);
    }

    public async Task DeleteResponseAsync(Guid responseId, CancellationToken ct = default)
    {
        var r = await db.PollResponses.FirstOrDefaultAsync(x => x.Id == responseId, ct);
        if (r is null) return;
        db.PollResponses.Remove(r);
        await db.SaveChangesAsync(ct);
    }

    public async Task DeleteAsync(Guid pollId, CancellationToken ct = default)
    {
        var p = await db.EventPolls.FirstOrDefaultAsync(x => x.Id == pollId, ct);
        if (p is null) return;
        db.EventPolls.Remove(p);
        await db.SaveChangesAsync(ct);
    }

    public async Task<string> ExportCsvAsync(Guid pollId, CancellationToken ct = default)
    {
        var poll = await db.EventPolls.Include(p => p.Options).Include(p => p.Responses).FirstOrDefaultAsync(p => p.Id == pollId, ct)
            ?? throw new InvalidOperationException("Poll nicht gefunden");
        var userIds = poll.Responses.Select(r => r.UserId).Distinct().ToList();
        var userMap = await db.Users.Where(u => userIds.Contains(u.Id))
            .Select(u => new { u.Id, u.DisplayName, u.Email }).ToDictionaryAsync(u => u.Id, u => u, ct);

        var sb = new StringBuilder();
        sb.AppendLine("User;Email;Option;Answer;FreeText;Size;Quantity;RespondedAt");
        foreach (var r in poll.Responses.OrderBy(r => r.RespondedAt))
        {
            var u = userMap.GetValueOrDefault(r.UserId);
            var optionLabel = poll.Options.FirstOrDefault(o => o.Id == r.OptionId)?.Label ?? "";
            sb.AppendLine($"\"{u?.DisplayName ?? r.UserId.ToString()}\";\"{u?.Email}\";\"{optionLabel}\";{r.Answer};\"{r.FreeTextAnswer ?? ""}\";\"{r.Size ?? ""}\";{r.Quantity};{r.RespondedAt:o}");
        }
        return sb.ToString();
    }
}
