using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Domain.Enums;
using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Domain.Import;
using Sheetstorm.Infrastructure.Auth;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Infrastructure.Import;

public class ImportService(
    AppDbContext db,
    IStorageService storageService,
    IAiMetadataService aiService,
    ILogger<ImportService> logger) : IImportService
{
    // ── Import Pipeline ───────────────────────────────────────────────────────

    public async Task<ImportResultDto> ImportAsync(
        Stream fileStream,
        string fileName,
        string contentType,
        Guid? kapelleId,
        Guid musikerId,
        CancellationToken ct = default)
    {
        if (kapelleId.HasValue)
            await RequireMitgliedschaftAsync(kapelleId.Value, musikerId);

        // 1. Upload to storage
        var storageKey = await storageService.UploadAsync(fileStream, fileName, contentType, ct);

        // 2. Create Stück entity in Pending state
        var stueck = new Stueck
        {
            KapelleID = kapelleId,
            MusikerID = kapelleId.HasValue ? null : musikerId,
            Titel = Path.GetFileNameWithoutExtension(fileName),
            OriginalDateiname = fileName,
            StorageKey = storageKey,
            ImportStatus = ImportStatus.Pending
        };

        db.Stuecke.Add(stueck);
        await db.SaveChangesAsync(ct);

        // 3. AI metadata extraction (best-effort)
        StueckMetadataDto? metadata = null;
        try
        {
            stueck.ImportStatus = ImportStatus.Processing;
            await db.SaveChangesAsync(ct);

            // Re-open stream for AI (seek back if possible)
            if (fileStream.CanSeek)
                fileStream.Position = 0;

            metadata = await aiService.ExtractMetadataAsync(fileStream, fileName, ct);

            // Apply extracted metadata
            if (!string.IsNullOrWhiteSpace(metadata.Titel))
                stueck.Titel = metadata.Titel;
            stueck.Komponist = metadata.Komponist;
            stueck.Tonart = metadata.Tonart;
            stueck.Taktart = metadata.Taktart;
            stueck.Tempo = metadata.Tempo;
            stueck.ImportStatus = ImportStatus.Completed;
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "AI metadata extraction failed for {FileName}", fileName);
            stueck.ImportStatus = ImportStatus.Failed;
        }

        await db.SaveChangesAsync(ct);

        return new ImportResultDto(
            stueck.Id,
            stueck.Titel,
            stueck.ImportStatus,
            metadata
        );
    }

    // ── CRUD ──────────────────────────────────────────────────────────────────

    public async Task<IReadOnlyList<StueckDto>> GetStueckeAsync(
        Guid kapelleId, Guid musikerId, CancellationToken ct = default)
    {
        await RequireMitgliedschaftAsync(kapelleId, musikerId);

        return await db.Stuecke
            .Where(s => s.KapelleID == kapelleId)
            .OrderByDescending(s => s.CreatedAt)
            .Select(s => ToDto(s))
            .ToListAsync(ct);
    }

    public async Task<StueckDto> GetStueckAsync(
        Guid kapelleId, Guid stueckId, Guid musikerId, CancellationToken ct = default)
    {
        await RequireMitgliedschaftAsync(kapelleId, musikerId);

        var stueck = await db.Stuecke
            .FirstOrDefaultAsync(s => s.Id == stueckId && s.KapelleID == kapelleId, ct)
            ?? throw new DomainException("STUECK_NOT_FOUND", "Stück nicht gefunden.", 404);

        return ToDto(stueck);
    }

    public async Task<StueckDto> CreateStueckAsync(
        Guid kapelleId, StueckCreateDto dto, Guid musikerId, CancellationToken ct = default)
    {
        await RequireMitgliedschaftAsync(kapelleId, musikerId);

        var stueck = new Stueck
        {
            KapelleID = kapelleId,
            Titel = dto.Titel.Trim(),
            Komponist = dto.Komponist?.Trim(),
            Arrangeur = dto.Arrangeur?.Trim(),
            VeroeffentlichungsJahr = dto.VeroeffentlichungsJahr,
            Tonart = dto.Tonart?.Trim(),
            Taktart = dto.Taktart?.Trim(),
            Tempo = dto.Tempo,
            Beschreibung = dto.Beschreibung?.Trim(),
            ImportStatus = ImportStatus.Completed
        };

        db.Stuecke.Add(stueck);
        await db.SaveChangesAsync(ct);

        return ToDto(stueck);
    }

    public async Task<StueckDto> UpdateStueckAsync(
        Guid kapelleId, Guid stueckId, StueckUpdateDto dto, Guid musikerId, CancellationToken ct = default)
    {
        await RequireMitgliedschaftAsync(kapelleId, musikerId);

        var stueck = await db.Stuecke
            .FirstOrDefaultAsync(s => s.Id == stueckId && s.KapelleID == kapelleId, ct)
            ?? throw new DomainException("STUECK_NOT_FOUND", "Stück nicht gefunden.", 404);

        stueck.Titel = dto.Titel.Trim();
        stueck.Komponist = dto.Komponist?.Trim();
        stueck.Arrangeur = dto.Arrangeur?.Trim();
        stueck.VeroeffentlichungsJahr = dto.VeroeffentlichungsJahr;
        stueck.Tonart = dto.Tonart?.Trim();
        stueck.Taktart = dto.Taktart?.Trim();
        stueck.Tempo = dto.Tempo;
        stueck.Beschreibung = dto.Beschreibung?.Trim();

        await db.SaveChangesAsync(ct);

        return ToDto(stueck);
    }

    public async Task DeleteStueckAsync(
        Guid kapelleId, Guid stueckId, Guid musikerId, CancellationToken ct = default)
    {
        await RequireMitgliedschaftAsync(kapelleId, musikerId);

        var stueck = await db.Stuecke
            .FirstOrDefaultAsync(s => s.Id == stueckId && s.KapelleID == kapelleId, ct)
            ?? throw new DomainException("STUECK_NOT_FOUND", "Stück nicht gefunden.", 404);

        // Delete from storage if a file was uploaded
        if (!string.IsNullOrEmpty(stueck.StorageKey))
        {
            try
            {
                await storageService.DeleteAsync(stueck.StorageKey, ct);
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "Failed to delete storage object {Key}", stueck.StorageKey);
            }
        }

        db.Stuecke.Remove(stueck);
        await db.SaveChangesAsync(ct);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private async Task RequireMitgliedschaftAsync(Guid kapelleId, Guid musikerId)
    {
        var isMember = await db.Mitgliedschaften
            .AnyAsync(m => m.KapelleID == kapelleId && m.MusikerID == musikerId && m.IstAktiv);

        if (!isMember)
            throw new DomainException("KAPELLE_NOT_FOUND", "Kapelle nicht gefunden oder kein Zugriff.", 404);
    }

    private static StueckDto ToDto(Stueck s) => new(
        s.Id,
        s.Titel,
        s.Komponist,
        s.Arrangeur,
        s.VeroeffentlichungsJahr,
        s.Tonart,
        s.Taktart,
        s.Tempo,
        s.Beschreibung,
        s.KapelleID,
        s.MusikerID,
        s.OriginalDateiname,
        s.ImportStatus,
        s.CreatedAt,
        s.UpdatedAt
    );
}
