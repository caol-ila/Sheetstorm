using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Infrastructure.Pagination;

namespace Sheetstorm.Tests.Pagination;

public class CursorHelperTests
{
    [Fact]
    public void Encode_ProducesBase64String()
    {
        var date = new DateTime(2025, 6, 15, 10, 30, 0, DateTimeKind.Utc);
        var id = Guid.NewGuid();

        var cursor = CursorHelper.Encode(date, id);

        Assert.NotNull(cursor);
        Assert.NotEmpty(cursor);
        // Should be valid Base64
        var bytes = Convert.FromBase64String(cursor);
        Assert.NotEmpty(bytes);
    }

    [Fact]
    public void Decode_RoundTrips_Correctly()
    {
        var date = new DateTime(2025, 6, 15, 10, 30, 0, DateTimeKind.Utc);
        var id = Guid.NewGuid();

        var cursor = CursorHelper.Encode(date, id);
        var (decodedDate, decodedId) = CursorHelper.Decode(cursor);

        Assert.Equal(date, decodedDate);
        Assert.Equal(id, decodedId);
    }

    [Fact]
    public void Decode_InvalidBase64_ThrowsDomainException()
    {
        var ex = Assert.Throws<DomainException>(() => CursorHelper.Decode("not-valid-base64!!!"));
        Assert.Equal("INVALID_CURSOR", ex.ErrorCode);
        Assert.Equal(400, ex.StatusCode);
    }

    [Fact]
    public void Decode_ValidBase64ButInvalidJson_ThrowsDomainException()
    {
        var cursor = Convert.ToBase64String("not json"u8.ToArray());

        var ex = Assert.Throws<DomainException>(() => CursorHelper.Decode(cursor));
        Assert.Equal("INVALID_CURSOR", ex.ErrorCode);
        Assert.Equal(400, ex.StatusCode);
    }

    [Fact]
    public void Decode_EmptyString_ThrowsDomainException()
    {
        Assert.Throws<DomainException>(() => CursorHelper.Decode(""));
    }

    [Fact]
    public void Encode_DifferentInputs_ProduceDifferentCursors()
    {
        var date = DateTime.UtcNow;
        var id1 = Guid.NewGuid();
        var id2 = Guid.NewGuid();

        var cursor1 = CursorHelper.Encode(date, id1);
        var cursor2 = CursorHelper.Encode(date, id2);

        Assert.NotEqual(cursor1, cursor2);
    }
}
