using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Identity;
using Sheetstorm.Domain.Music;
using Sheetstorm.Infrastructure.Persistence;
using Sheetstorm.Web.Services;

namespace Sheetstorm.Web.Application;

public sealed record PieceListItem(Guid Id, string Title, string? Composer, int? Difficulty, string? Genre, int PartsCount, bool HasMyPart);

public sealed record PartViewItem(Guid Id, Guid InstrumentId, string DisplayName, string? Transposition, string Family, bool IsPreferredForUser, IReadOnlyList<PartFileViewItem> Files);
public sealed record PartFileViewItem(Guid Id, PartFileKind Kind, string OriginalFileName, long SizeBytes, int? PageNumber = null);

public sealed class PieceService(SheetstormDbContext db, LocalFileStore store)
{
    public async Task<List<PieceListItem>> SearchAsync(Guid bandId, Guid currentUserId, string? query, string? genre, int? minDifficulty, int? maxDifficulty, bool onlyMyPart, CancellationToken ct = default)
    {
        var preferredInstruments = await db.Memberships
            .Where(m => m.BandId == bandId && m.UserId == currentUserId)
            .SelectMany(m => m.Instruments.Select(i => i.InstrumentId))
            .ToListAsync(ct);

        var pieces = db.Pieces.Where(p => p.BandId == bandId && p.DeletedAt == null);

        if (!string.IsNullOrWhiteSpace(query))
        {
            var q = query.Trim().ToLower();
            pieces = pieces.Where(p =>
                p.Title.ToLower().Contains(q) ||
                (p.Composer != null && p.Composer.ToLower().Contains(q)) ||
                (p.Tags != null && p.Tags.ToLower().Contains(q)));
        }
        if (!string.IsNullOrWhiteSpace(genre))
        {
            pieces = pieces.Where(p => p.Genre == genre);
        }
        if (minDifficulty is not null) pieces = pieces.Where(p => p.Difficulty != null && p.Difficulty >= minDifficulty);
        if (maxDifficulty is not null) pieces = pieces.Where(p => p.Difficulty != null && p.Difficulty <= maxDifficulty);

        var rows = await pieces
            .OrderBy(p => p.Title)
            .Select(p => new PieceListItem(
                p.Id, p.Title, p.Composer, p.Difficulty, p.Genre,
                p.Parts.Count(pp => !pp.Retired),
                p.Parts.Any(pp => preferredInstruments.Contains(pp.InstrumentId))))
            .ToListAsync(ct);

        if (onlyMyPart) rows = rows.Where(r => r.HasMyPart).ToList();
        return rows;
    }

    public async Task<List<string>> GetGenresAsync(Guid bandId, CancellationToken ct = default)
        => await db.Pieces
            .Where(p => p.BandId == bandId && p.DeletedAt == null && p.Genre != null && p.Genre != "")
            .Select(p => p.Genre!)
            .Distinct()
            .OrderBy(g => g)
            .ToListAsync(ct);

    public async Task<Piece?> GetAsync(Guid pieceId, CancellationToken ct = default)
        => await db.Pieces
            .Include(p => p.Parts.Where(pp => !pp.Retired))
                .ThenInclude(pp => pp.Instrument)
            .Include(p => p.Parts.Where(pp => !pp.Retired))
                .ThenInclude(pp => pp.Files)
            .FirstOrDefaultAsync(p => p.Id == pieceId, ct);

    public async Task<Piece> CreateAsync(Guid bandId, string title, string? composer, string? genre, int? difficulty, CancellationToken ct = default)
    {
        var piece = Piece.Create(bandId, title);
        piece.UpdateMetadata(title, null, composer, null, null, null, null, null, null, null, difficulty, genre, null, null);
        db.Pieces.Add(piece);
        await db.SaveChangesAsync(ct);
        return piece;
    }

    public async Task SoftDeleteAsync(Guid pieceId, CancellationToken ct = default)
    {
        var p = await db.Pieces.FirstOrDefaultAsync(x => x.Id == pieceId, ct);
        if (p is null) return;
        p.SoftDelete();
        await db.SaveChangesAsync(ct);
    }

    public async Task UpdateMetadataAsync(Guid pieceId, string title, string? composer, string? genre, int? difficulty, string? notes, CancellationToken ct = default)
    {
        var p = await db.Pieces.FirstOrDefaultAsync(x => x.Id == pieceId, ct);
        if (p is null) return;
        p.UpdateMetadata(title, p.Subtitle, composer, p.Arranger, p.Publisher, p.PublisherNumber,
            p.KeySignature, p.TimeSignature, p.Tempo, p.DurationSeconds, difficulty, genre, p.Tags, notes);
        await db.SaveChangesAsync(ct);
    }

    public async Task<Part> AddPartAsync(Guid pieceId, Guid instrumentId, string displayName, string? transposition, CancellationToken ct = default)
    {
        var part = Part.Create(pieceId, instrumentId, displayName, transposition);
        db.Parts.Add(part);
        await db.SaveChangesAsync(ct);
        return part;
    }

    public async Task<PartFile> AttachPartFileAsync(Guid partId, Stream content, string fileName, PartFileKind kind, CancellationToken ct = default)
    {
        var key = await store.SaveAsync(content, $"parts/{partId}", fileName, ct);
        var size = store.GetSize(key);
        var pf = PartFile.Create(partId, kind, key, fileName, size);
        db.PartFiles.Add(pf);
        await db.SaveChangesAsync(ct);
        return pf;
    }

    public async Task<List<PartViewItem>> GetSortedPartsForUserAsync(Guid pieceId, Guid bandId, Guid userId, CancellationToken ct = default)
    {
        var prefs = await db.Memberships
            .Where(m => m.BandId == bandId && m.UserId == userId)
            .SelectMany(m => m.Instruments.Select(i => new { i.InstrumentId, i.IsPrimary }))
            .ToListAsync(ct);

        var preferredInstrumentIds = prefs.Where(p => p.IsPrimary).Select(p => p.InstrumentId).ToList();
        var alternativeInstrumentIds = prefs.Where(p => !p.IsPrimary).Select(p => p.InstrumentId).ToList();

        var parts = await db.Parts
            .Where(p => p.PieceId == pieceId && !p.Retired)
            .Include(p => p.Instrument)
            .Include(p => p.Files)
            .ToListAsync(ct);

        return parts
            .Select(p => new PartViewItem(
                p.Id, p.InstrumentId, p.DisplayName, p.Transposition,
                p.Instrument.Family.ToString(),
                preferredInstrumentIds.Contains(p.InstrumentId),
                p.Files.Select(f => new PartFileViewItem(f.Id, f.Kind, f.OriginalFileName, f.SizeBytes, f.PageNumber)).ToList()))
            .OrderByDescending(p => p.IsPreferredForUser)
            .ThenByDescending(p => alternativeInstrumentIds.Contains(p.InstrumentId))
            .ThenBy(p => p.Family)
            .ThenBy(p => p.DisplayName)
            .ToList();
    }
}
