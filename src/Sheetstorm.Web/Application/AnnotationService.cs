using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Music;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Web.Application;

public sealed class AnnotationService(SheetstormDbContext db)
{
    public async Task<Annotation?> GetAsync(Guid partId, Guid userId, int page, CancellationToken ct = default)
        => await db.Annotations.FirstOrDefaultAsync(a => a.PartId == partId && a.UserId == userId && a.Page == page, ct);

    public async Task SaveAsync(Guid partId, Guid userId, int page, string layerJson, CancellationToken ct = default)
    {
        var existing = await GetAsync(partId, userId, page, ct);
        if (existing is null)
        {
            db.Annotations.Add(Annotation.Create(partId, userId, page, layerJson));
        }
        else
        {
            existing.Update(layerJson);
        }
        await db.SaveChangesAsync(ct);
    }

    public async Task DeleteAsync(Guid partId, Guid userId, int page, CancellationToken ct = default)
    {
        var existing = await GetAsync(partId, userId, page, ct);
        if (existing is null) return;
        db.Annotations.Remove(existing);
        await db.SaveChangesAsync(ct);
    }
}
