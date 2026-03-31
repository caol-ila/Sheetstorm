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
    IBandAuthorizationService bandAuth,
    IStorageService storageService,
    IAiMetadataService aiService,
    ILogger<ImportService> logger) : IImportService
{
    // ── Import Pipeline ───────────────────────────────────────────────────────

    public async Task<ImportResultDto> ImportAsync(
        Stream fileStream,
        string fileName,
        string contentType,
        Guid? bandId,
        Guid musicianId,
        CancellationToken ct = default)
    {
        if (bandId.HasValue)
            await bandAuth.RequireMembershipAsync(bandId.Value, musicianId);

        // 1. Upload to storage
        var storageKey = await storageService.UploadAsync(fileStream, fileName, contentType, ct);

        // 2. Create Stück entity in Pending state
        var piece = new Piece
        {
            BandId = bandId,
            MusicianId = bandId.HasValue ? null : musicianId,
            Title = Path.GetFileNameWithoutExtension(fileName),
            OriginalFileName = fileName,
            StorageKey = storageKey,
            ImportStatus = ImportStatus.Pending
        };

        db.Pieces.Add(piece);
        await db.SaveChangesAsync(ct);

        // 3. AI metadata extraction (best-effort)
        PieceMetadataDto? metadata = null;
        try
        {
            piece.ImportStatus = ImportStatus.Processing;
            await db.SaveChangesAsync(ct);

            // Re-open stream for AI (seek back if possible)
            if (fileStream.CanSeek)
                fileStream.Position = 0;

            metadata = await aiService.ExtractMetadataAsync(fileStream, fileName, ct);

            // Apply extracted metadata
            if (!string.IsNullOrWhiteSpace(metadata.Title))
                piece.Title = metadata.Title;
            piece.Composer = metadata.Composer;
            piece.MusicalKey = metadata.MusicalKey;
            piece.TimeSignature = metadata.TimeSignature;
            piece.Tempo = metadata.Tempo;
            piece.ImportStatus = ImportStatus.Completed;
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "AI metadata extraction failed for {FileName}", fileName);
            piece.ImportStatus = ImportStatus.Failed;
        }

        await db.SaveChangesAsync(ct);

        return new ImportResultDto(
            piece.Id,
            piece.Title,
            piece.ImportStatus,
            metadata
        );
    }

    // ── CRUD ──────────────────────────────────────────────────────────────────

    public async Task<IReadOnlyList<PieceDto>> GetPiecesAsync(
        Guid bandId, Guid musicianId, CancellationToken ct = default)
    {
        await bandAuth.RequireMembershipAsync(bandId, musicianId);

        return await db.Pieces
            .Where(s => s.BandId == bandId)
            .OrderByDescending(s => s.CreatedAt)
            .Select(s => ToDto(s))
            .ToListAsync(ct);
    }

    public async Task<PieceDto> GetPieceAsync(
        Guid bandId, Guid pieceId, Guid musicianId, CancellationToken ct = default)
    {
        await bandAuth.RequireMembershipAsync(bandId, musicianId);

        var piece = await db.Pieces
            .FirstOrDefaultAsync(s => s.Id == pieceId && s.BandId == bandId, ct)
            ?? throw new DomainException("PIECE_NOT_FOUND", "Piece not found.", 404);

        return ToDto(piece);
    }

    public async Task<PieceDto> CreatePieceAsync(
        Guid bandId, PieceCreateDto dto, Guid musicianId, CancellationToken ct = default)
    {
        await bandAuth.RequireMembershipAsync(bandId, musicianId);

        var piece = new Piece
        {
            BandId = bandId,
            Title = dto.Title.Trim(),
            Composer = dto.Composer?.Trim(),
            Arranger = dto.Arranger?.Trim(),
            PublicationYear = dto.PublicationYear,
            MusicalKey = dto.MusicalKey?.Trim(),
            TimeSignature = dto.TimeSignature?.Trim(),
            Tempo = dto.Tempo,
            Description = dto.Description?.Trim(),
            ImportStatus = ImportStatus.Completed
        };

        db.Pieces.Add(piece);
        await db.SaveChangesAsync(ct);

        return ToDto(piece);
    }

    public async Task<PieceDto> UpdatePieceAsync(
        Guid bandId, Guid pieceId, PieceUpdateDto dto, Guid musicianId, CancellationToken ct = default)
    {
        await bandAuth.RequireMembershipAsync(bandId, musicianId);

        var piece = await db.Pieces
            .FirstOrDefaultAsync(s => s.Id == pieceId && s.BandId == bandId, ct)
            ?? throw new DomainException("PIECE_NOT_FOUND", "Piece not found.", 404);

        piece.Title = dto.Title.Trim();
        piece.Composer = dto.Composer?.Trim();
        piece.Arranger = dto.Arranger?.Trim();
        piece.PublicationYear = dto.PublicationYear;
        piece.MusicalKey = dto.MusicalKey?.Trim();
        piece.TimeSignature = dto.TimeSignature?.Trim();
        piece.Tempo = dto.Tempo;
        piece.Description = dto.Description?.Trim();

        await db.SaveChangesAsync(ct);

        return ToDto(piece);
    }

    public async Task DeletePieceAsync(
        Guid bandId, Guid pieceId, Guid musicianId, CancellationToken ct = default)
    {
        await bandAuth.RequireMembershipAsync(bandId, musicianId);

        var piece = await db.Pieces
            .FirstOrDefaultAsync(s => s.Id == pieceId && s.BandId == bandId, ct)
            ?? throw new DomainException("PIECE_NOT_FOUND", "Piece not found.", 404);

        // Delete from storage if a file was uploaded
        if (!string.IsNullOrEmpty(piece.StorageKey))
        {
            try
            {
                await storageService.DeleteAsync(piece.StorageKey, ct);
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "Failed to delete storage object {Key}", piece.StorageKey);
            }
        }

        db.Pieces.Remove(piece);
        await db.SaveChangesAsync(ct);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private static PieceDto ToDto(Piece s) => new(
        s.Id,
        s.Title,
        s.Composer,
        s.Arranger,
        s.PublicationYear,
        s.MusicalKey,
        s.TimeSignature,
        s.Tempo,
        s.Description,
        s.BandId,
        s.MusicianId,
        s.OriginalFileName,
        s.ImportStatus,
        s.CreatedAt,
        s.UpdatedAt
    );
}
