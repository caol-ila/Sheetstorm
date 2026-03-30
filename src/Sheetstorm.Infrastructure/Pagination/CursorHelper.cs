using System.Text;
using System.Text.Json;
using Sheetstorm.Domain.Exceptions;

namespace Sheetstorm.Infrastructure.Pagination;

/// <summary>
/// Encodes/decodes opaque cursors for cursor-based pagination.
/// Cursor = Base64(JSON {"createdAt":"...","id":"..."}).
/// </summary>
public static class CursorHelper
{
    private record CursorPayload(DateTime CreatedAt, Guid Id);

    public static string Encode(DateTime createdAt, Guid id)
    {
        var payload = new CursorPayload(createdAt, id);
        var json = JsonSerializer.Serialize(payload);
        return Convert.ToBase64String(Encoding.UTF8.GetBytes(json));
    }

    public static (DateTime CreatedAt, Guid Id) Decode(string cursor)
    {
        try
        {
            var json = Encoding.UTF8.GetString(Convert.FromBase64String(cursor));
            var payload = JsonSerializer.Deserialize<CursorPayload>(json)
                ?? throw new FormatException("Null payload");
            return (payload.CreatedAt, payload.Id);
        }
        catch (Exception ex) when (ex is FormatException or JsonException or ArgumentException)
        {
            throw new DomainException("INVALID_CURSOR", "The pagination cursor is invalid.", 400);
        }
    }
}
