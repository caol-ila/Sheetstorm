using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Domain.Setlists;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Infrastructure.Setlists;

public class SetlistService(AppDbContext db) : ISetlistService
{
    public async Task<IReadOnlyList<SetlistDto>> GetAllAsync(Guid bandId, Guid musicianId, CancellationToken ct)
    {
        await RequireMembershipAsync(bandId, musicianId, ct);

        return await db.Set<Setlist>()
            .Where(s => s.BandId == bandId)
            .OrderByDescending(s => s.CreatedAt)
            .Select(s => new SetlistDto(
                s.Id,
                s.Name,
                s.Description,
                s.Type,
                s.Date,
                s.StartTime,
                s.EventId,
                s.Entries.Count,
                s.Entries.Sum(e => (int?)e.DurationSeconds),
                s.CreatedAt
            ))
            .ToListAsync(ct);
    }

    public async Task<SetlistDetailDto> GetByIdAsync(Guid bandId, Guid setlistId, Guid musicianId, CancellationToken ct)
    {
        await RequireMembershipAsync(bandId, musicianId, ct);

        var setlist = await db.Set<Setlist>()
            .Include(s => s.Entries.OrderBy(e => e.Position))
            .ThenInclude(e => e.Piece)
            .FirstOrDefaultAsync(s => s.Id == setlistId && s.BandId == bandId, ct)
            ?? throw new DomainException("NOT_FOUND", "Setlist not found.", 404);

        var entries = setlist.Entries
            .OrderBy(e => e.Position)
            .Select(e => new SetlistEntryDto(
                e.Id,
                e.Position,
                e.PieceId,
                e.Piece?.Title,
                e.Piece?.Composer,
                e.IsPlaceholder,
                e.PlaceholderTitle,
                e.PlaceholderComposer,
                e.Notes,
                e.DurationSeconds
            ))
            .ToList();

        return new SetlistDetailDto(
            setlist.Id,
            setlist.Name,
            setlist.Description,
            setlist.Type,
            setlist.Date,
            setlist.StartTime,
            setlist.EventId,
            entries,
            entries.Sum(e => e.DurationSeconds),
            setlist.CreatedAt
        );
    }

    public async Task<SetlistDetailDto> CreateAsync(Guid bandId, CreateSetlistRequest request, Guid musicianId, CancellationToken ct)
    {
        var membership = await RequireMembershipAsync(bandId, musicianId, ct);
        
        if (membership.Role != MemberRole.Administrator && membership.Role != MemberRole.Conductor)
            throw new DomainException("FORBIDDEN", "Only admins and conductors can create setlists.", 403);

        var setlist = new Setlist
        {
            BandId = bandId,
            Name = request.Name.Trim(),
            Description = request.Description?.Trim(),
            Type = request.Type,
            Date = request.Date,
            StartTime = request.StartTime,
            EventId = request.EventId
        };

        db.Set<Setlist>().Add(setlist);
        await db.SaveChangesAsync(ct);

        return new SetlistDetailDto(
            setlist.Id,
            setlist.Name,
            setlist.Description,
            setlist.Type,
            setlist.Date,
            setlist.StartTime,
            setlist.EventId,
            Array.Empty<SetlistEntryDto>(),
            null,
            setlist.CreatedAt
        );
    }

    public async Task<SetlistDetailDto> UpdateAsync(Guid bandId, Guid setlistId, UpdateSetlistRequest request, Guid musicianId, CancellationToken ct)
    {
        var membership = await RequireMembershipAsync(bandId, musicianId, ct);
        
        if (membership.Role != MemberRole.Administrator && membership.Role != MemberRole.Conductor)
            throw new DomainException("FORBIDDEN", "Only admins and conductors can update setlists.", 403);

        var setlist = await db.Set<Setlist>()
            .Include(s => s.Entries.OrderBy(e => e.Position))
            .ThenInclude(e => e.Piece)
            .FirstOrDefaultAsync(s => s.Id == setlistId && s.BandId == bandId, ct)
            ?? throw new DomainException("NOT_FOUND", "Setlist not found.", 404);

        setlist.Name = request.Name.Trim();
        setlist.Description = request.Description?.Trim();
        setlist.Type = request.Type;
        setlist.Date = request.Date;
        setlist.StartTime = request.StartTime;
        setlist.EventId = request.EventId;

        await db.SaveChangesAsync(ct);

        var entries = setlist.Entries
            .OrderBy(e => e.Position)
            .Select(e => new SetlistEntryDto(
                e.Id,
                e.Position,
                e.PieceId,
                e.Piece?.Title,
                e.Piece?.Composer,
                e.IsPlaceholder,
                e.PlaceholderTitle,
                e.PlaceholderComposer,
                e.Notes,
                e.DurationSeconds
            ))
            .ToList();

        return new SetlistDetailDto(
            setlist.Id,
            setlist.Name,
            setlist.Description,
            setlist.Type,
            setlist.Date,
            setlist.StartTime,
            setlist.EventId,
            entries,
            entries.Sum(e => e.DurationSeconds),
            setlist.CreatedAt
        );
    }

    public async Task DeleteAsync(Guid bandId, Guid setlistId, Guid musicianId, CancellationToken ct)
    {
        var membership = await RequireMembershipAsync(bandId, musicianId, ct);
        
        if (membership.Role != MemberRole.Administrator && membership.Role != MemberRole.Conductor)
            throw new DomainException("FORBIDDEN", "Only admins and conductors can delete setlists.", 403);

        var setlist = await db.Set<Setlist>()
            .FirstOrDefaultAsync(s => s.Id == setlistId && s.BandId == bandId, ct)
            ?? throw new DomainException("NOT_FOUND", "Setlist not found.", 404);

        db.Set<Setlist>().Remove(setlist);
        await db.SaveChangesAsync(ct);
    }

    public async Task<SetlistEntryDto> AddEntryAsync(Guid bandId, Guid setlistId, AddSetlistEntryRequest request, Guid musicianId, CancellationToken ct)
    {
        var membership = await RequireMembershipAsync(bandId, musicianId, ct);
        
        if (membership.Role != MemberRole.Administrator && membership.Role != MemberRole.Conductor)
            throw new DomainException("FORBIDDEN", "Only admins and conductors can modify setlists.", 403);

        var setlist = await db.Set<Setlist>()
            .Include(s => s.Entries)
            .FirstOrDefaultAsync(s => s.Id == setlistId && s.BandId == bandId, ct)
            ?? throw new DomainException("NOT_FOUND", "Setlist not found.", 404);

        if (request.IsPlaceholder && string.IsNullOrWhiteSpace(request.PlaceholderTitle))
            throw new DomainException("VALIDATION_ERROR", "Placeholder title is required.", 400);

        if (!request.IsPlaceholder && request.PieceId == null)
            throw new DomainException("VALIDATION_ERROR", "Piece ID is required for non-placeholder entries.", 400);

        Piece? piece = null;
        if (request.PieceId.HasValue)
        {
            piece = await db.Set<Piece>()
                .FirstOrDefaultAsync(p => p.Id == request.PieceId.Value && p.BandId == bandId, ct);
            
            if (piece == null)
                throw new DomainException("NOT_FOUND", "Piece not found.", 404);
        }

        var maxPosition = setlist.Entries.Any() ? setlist.Entries.Max(e => e.Position) : -1;
        
        var entry = new SetlistEntry
        {
            SetlistId = setlistId,
            PieceId = request.PieceId,
            Position = maxPosition + 1,
            IsPlaceholder = request.IsPlaceholder,
            PlaceholderTitle = request.PlaceholderTitle?.Trim(),
            PlaceholderComposer = request.PlaceholderComposer?.Trim(),
            Notes = request.Notes?.Trim(),
            DurationSeconds = request.DurationSeconds
        };

        db.Set<SetlistEntry>().Add(entry);
        await db.SaveChangesAsync(ct);

        return new SetlistEntryDto(
            entry.Id,
            entry.Position,
            entry.PieceId,
            piece?.Title,
            piece?.Composer,
            entry.IsPlaceholder,
            entry.PlaceholderTitle,
            entry.PlaceholderComposer,
            entry.Notes,
            entry.DurationSeconds
        );
    }

    public async Task<SetlistEntryDto> UpdateEntryAsync(Guid bandId, Guid setlistId, Guid entryId, UpdateSetlistEntryRequest request, Guid musicianId, CancellationToken ct)
    {
        var membership = await RequireMembershipAsync(bandId, musicianId, ct);
        
        if (membership.Role != MemberRole.Administrator && membership.Role != MemberRole.Conductor)
            throw new DomainException("FORBIDDEN", "Only admins and conductors can modify setlists.", 403);

        var entry = await db.Set<SetlistEntry>()
            .Include(e => e.Setlist)
            .Include(e => e.Piece)
            .FirstOrDefaultAsync(e => e.Id == entryId && e.SetlistId == setlistId && e.Setlist.BandId == bandId, ct)
            ?? throw new DomainException("NOT_FOUND", "Setlist entry not found.", 404);

        entry.Notes = request.Notes?.Trim();
        entry.DurationSeconds = request.DurationSeconds;

        await db.SaveChangesAsync(ct);

        return new SetlistEntryDto(
            entry.Id,
            entry.Position,
            entry.PieceId,
            entry.Piece?.Title,
            entry.Piece?.Composer,
            entry.IsPlaceholder,
            entry.PlaceholderTitle,
            entry.PlaceholderComposer,
            entry.Notes,
            entry.DurationSeconds
        );
    }

    public async Task DeleteEntryAsync(Guid bandId, Guid setlistId, Guid entryId, Guid musicianId, CancellationToken ct)
    {
        var membership = await RequireMembershipAsync(bandId, musicianId, ct);
        
        if (membership.Role != MemberRole.Administrator && membership.Role != MemberRole.Conductor)
            throw new DomainException("FORBIDDEN", "Only admins and conductors can modify setlists.", 403);

        var entry = await db.Set<SetlistEntry>()
            .Include(e => e.Setlist)
            .FirstOrDefaultAsync(e => e.Id == entryId && e.SetlistId == setlistId && e.Setlist.BandId == bandId, ct)
            ?? throw new DomainException("NOT_FOUND", "Setlist entry not found.", 404);

        db.Set<SetlistEntry>().Remove(entry);
        await db.SaveChangesAsync(ct);
    }

    public async Task ReorderEntriesAsync(Guid bandId, Guid setlistId, ReorderEntriesRequest request, Guid musicianId, CancellationToken ct)
    {
        var membership = await RequireMembershipAsync(bandId, musicianId, ct);
        
        if (membership.Role != MemberRole.Administrator && membership.Role != MemberRole.Conductor)
            throw new DomainException("FORBIDDEN", "Only admins and conductors can modify setlists.", 403);

        var setlist = await db.Set<Setlist>()
            .Include(s => s.Entries)
            .FirstOrDefaultAsync(s => s.Id == setlistId && s.BandId == bandId, ct)
            ?? throw new DomainException("NOT_FOUND", "Setlist not found.", 404);

        if (request.EntryIds.Count != setlist.Entries.Count)
            throw new DomainException("VALIDATION_ERROR", "Entry ID count mismatch.", 400);

        var entries = setlist.Entries.ToList();
        foreach (var entryId in request.EntryIds)
        {
            if (!entries.Any(e => e.Id == entryId))
                throw new DomainException("VALIDATION_ERROR", "Invalid entry ID in reorder request.", 400);
        }

        for (int i = 0; i < request.EntryIds.Count; i++)
        {
            var entry = entries.First(e => e.Id == request.EntryIds[i]);
            entry.Position = i;
        }

        await db.SaveChangesAsync(ct);
    }

    public async Task<SetlistDetailDto> DuplicateAsync(Guid bandId, Guid setlistId, Guid musicianId, CancellationToken ct)
    {
        var membership = await RequireMembershipAsync(bandId, musicianId, ct);
        
        if (membership.Role != MemberRole.Administrator && membership.Role != MemberRole.Conductor)
            throw new DomainException("FORBIDDEN", "Only admins and conductors can duplicate setlists.", 403);

        var original = await db.Set<Setlist>()
            .Include(s => s.Entries.OrderBy(e => e.Position))
            .ThenInclude(e => e.Piece)
            .FirstOrDefaultAsync(s => s.Id == setlistId && s.BandId == bandId, ct)
            ?? throw new DomainException("NOT_FOUND", "Setlist not found.", 404);

        var duplicate = new Setlist
        {
            BandId = bandId,
            Name = $"{original.Name} (Copy)",
            Description = original.Description,
            Type = original.Type,
            Date = original.Date,
            StartTime = original.StartTime,
            EventId = original.EventId
        };

        db.Set<Setlist>().Add(duplicate);
        await db.SaveChangesAsync(ct);

        foreach (var originalEntry in original.Entries.OrderBy(e => e.Position))
        {
            var duplicateEntry = new SetlistEntry
            {
                SetlistId = duplicate.Id,
                PieceId = originalEntry.PieceId,
                Position = originalEntry.Position,
                IsPlaceholder = originalEntry.IsPlaceholder,
                PlaceholderTitle = originalEntry.PlaceholderTitle,
                PlaceholderComposer = originalEntry.PlaceholderComposer,
                Notes = originalEntry.Notes,
                DurationSeconds = originalEntry.DurationSeconds
            };
            db.Set<SetlistEntry>().Add(duplicateEntry);
        }

        await db.SaveChangesAsync(ct);

        var entries = duplicate.Entries
            .OrderBy(e => e.Position)
            .Select(e => new SetlistEntryDto(
                e.Id,
                e.Position,
                e.PieceId,
                e.Piece?.Title,
                e.Piece?.Composer,
                e.IsPlaceholder,
                e.PlaceholderTitle,
                e.PlaceholderComposer,
                e.Notes,
                e.DurationSeconds
            ))
            .ToList();

        return new SetlistDetailDto(
            duplicate.Id,
            duplicate.Name,
            duplicate.Description,
            duplicate.Type,
            duplicate.Date,
            duplicate.StartTime,
            duplicate.EventId,
            entries,
            entries.Sum(e => e.DurationSeconds),
            duplicate.CreatedAt
        );
    }

    private async Task<Membership> RequireMembershipAsync(Guid bandId, Guid musicianId, CancellationToken ct)
    {
        var m = await db.Set<Membership>()
            .FirstOrDefaultAsync(m => m.BandId == bandId && m.MusicianId == musicianId && m.IsActive, ct);

        return m ?? throw new DomainException("BAND_NOT_FOUND", "Band not found or no access.", 404);
    }
}
