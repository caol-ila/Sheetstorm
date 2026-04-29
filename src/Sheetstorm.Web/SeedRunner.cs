using Microsoft.EntityFrameworkCore;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Web;

public static class SeedRunner
{
    public static async Task RunAsync(SheetstormDbContext db, CancellationToken ct = default)
    {
        if (!await db.Instruments.AnyAsync(ct))
        {
            db.Instruments.AddRange(InstrumentSeed.All);
            await db.SaveChangesAsync(ct);
        }
    }
}
