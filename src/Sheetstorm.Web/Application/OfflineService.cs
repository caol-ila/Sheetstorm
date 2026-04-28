using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Music;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Web.Application;

public sealed record OfflineUrlList(IReadOnlyList<string> Urls);

public sealed class OfflineService(SheetstormDbContext db)
{
    public async Task<bool> IsMarkedAsync(Guid userId, Guid pieceId, CancellationToken ct = default)
        => await db.OfflineWishes.AnyAsync(w => w.UserId == userId && w.PieceId == pieceId, ct);

    public async Task<HashSet<Guid>> GetMarkedPiecesAsync(Guid userId, CancellationToken ct = default)
        => (await db.OfflineWishes.Where(w => w.UserId == userId)
                .Select(w => w.PieceId).ToListAsync(ct)).ToHashSet();

    public async Task SetAsync(Guid userId, Guid pieceId, bool offline, CancellationToken ct = default)
    {
        var existing = await db.OfflineWishes.FirstOrDefaultAsync(w => w.UserId == userId && w.PieceId == pieceId, ct);
        if (offline && existing is null)
        {
            db.OfflineWishes.Add(OfflineWish.Create(userId, pieceId));
            await db.SaveChangesAsync(ct);
        }
        else if (!offline && existing is not null)
        {
            db.OfflineWishes.Remove(existing);
            await db.SaveChangesAsync(ct);
        }
    }

    /// <summary>
    /// Liefert alle Datei-URLs (relative Pfade) für die offline markierten Werke des Users.
    /// Dies wird vom Service Worker beim Sync-Lauf abgerufen und in den Cache gelegt.
    /// </summary>
    public async Task<OfflineUrlList> GetUrlsToCacheAsync(Guid userId, CancellationToken ct = default)
    {
        var pieceIds = await db.OfflineWishes.Where(w => w.UserId == userId).Select(w => w.PieceId).ToListAsync(ct);
        var urls = await db.PartFiles
            .Where(f => db.Parts.Where(p => pieceIds.Contains(p.PieceId)).Select(p => p.Id).Contains(f.PartId))
            .Select(f => $"/files/parts/{f.PartId}/{f.Id}")
            .ToListAsync(ct);
        return new OfflineUrlList(urls);
    }
}
