using System.ComponentModel.DataAnnotations;
using System.Reflection;
using Sheetstorm.Domain.Communication;
using Sheetstorm.Domain.Events;
using Sheetstorm.Domain.Gema;
using Sheetstorm.Domain.Polls;
using Sheetstorm.Domain.Shifts;
using Sheetstorm.Domain.Substitutes;

namespace Sheetstorm.Tests.Validation;

/// <summary>
/// Verifies that request models declare StringLength constraints on their properties.
/// ASP.NET Core model binding uses PropertyInfo.GetCustomAttributes() (not TypeDescriptor)
/// to find validation attributes, so reflection is the correct mechanism to verify
/// that the constraints are in place and will be enforced at model-binding time (400).
/// </summary>
public class RequestModelValidationTests
{
    private static StringLengthAttribute? GetStringLength(Type type, string propertyName)
    {
        // Check property first (if attribute is on synthesized property)
        var prop = type.GetProperty(propertyName);
        if (prop != null)
        {
            var fromProp = prop.GetCustomAttribute<StringLengthAttribute>();
            if (fromProp != null) return fromProp;
        }

        // Fall back to constructor parameter (positional record params carry the attribute)
        return type.GetConstructors().FirstOrDefault()
            ?.GetParameters()
            .FirstOrDefault(p => string.Equals(p.Name, propertyName, StringComparison.OrdinalIgnoreCase))
            ?.GetCustomAttribute<StringLengthAttribute>();
    }

    // ── Post ──────────────────────────────────────────────────────────────────

    [Fact]
    public void CreatePostRequest_Title_HasMaxLength120()
    {
        var attr = GetStringLength(typeof(CreatePostRequest), "Title");
        Assert.NotNull(attr);
        Assert.Equal(120, attr.MaximumLength);
    }

    [Fact]
    public void CreatePostRequest_Content_HasMaxLength5000()
    {
        var attr = GetStringLength(typeof(CreatePostRequest), "Content");
        Assert.NotNull(attr);
        Assert.Equal(5000, attr.MaximumLength);
    }

    [Fact]
    public void CreatePostCommentRequest_Content_HasMaxLength1000()
    {
        var attr = GetStringLength(typeof(CreatePostCommentRequest), "Content");
        Assert.NotNull(attr);
        Assert.Equal(1000, attr.MaximumLength);
    }

    [Fact]
    public void UpdatePostRequest_Title_HasMaxLength120()
    {
        var attr = GetStringLength(typeof(UpdatePostRequest), "Title");
        Assert.NotNull(attr);
        Assert.Equal(120, attr.MaximumLength);
    }

    // ── Event ─────────────────────────────────────────────────────────────────

    [Fact]
    public void CreateEventRequest_Title_HasMaxLength100()
    {
        var attr = GetStringLength(typeof(CreateEventRequest), "Title");
        Assert.NotNull(attr);
        Assert.Equal(100, attr.MaximumLength);
    }

    [Fact]
    public void CreateEventRequest_Description_HasMaxLength1000()
    {
        var attr = GetStringLength(typeof(CreateEventRequest), "Description");
        Assert.NotNull(attr);
        Assert.Equal(1000, attr.MaximumLength);
    }

    [Fact]
    public void CreateEventRequest_Location_HasMaxLength200()
    {
        var attr = GetStringLength(typeof(CreateEventRequest), "Location");
        Assert.NotNull(attr);
        Assert.Equal(200, attr.MaximumLength);
    }

    [Fact]
    public void CreateEventRequest_RepeatRule_HasMaxLength100()
    {
        var attr = GetStringLength(typeof(CreateEventRequest), "RepeatRule");
        Assert.NotNull(attr);
        Assert.Equal(100, attr.MaximumLength);
    }

    [Fact]
    public void UpdateEventRequest_RepeatRule_HasMaxLength100()
    {
        var attr = GetStringLength(typeof(UpdateEventRequest), "RepeatRule");
        Assert.NotNull(attr);
        Assert.Equal(100, attr.MaximumLength);
    }

    // ── Shift ─────────────────────────────────────────────────────────────────

    [Fact]
    public void CreateShiftRequest_Name_HasMaxLength80()
    {
        var attr = GetStringLength(typeof(CreateShiftRequest), "Name");
        Assert.NotNull(attr);
        Assert.Equal(80, attr.MaximumLength);
    }

    [Fact]
    public void CreateShiftRequest_Description_HasMaxLength200()
    {
        var attr = GetStringLength(typeof(CreateShiftRequest), "Description");
        Assert.NotNull(attr);
        Assert.Equal(200, attr.MaximumLength);
    }

    [Fact]
    public void CreateShiftPlanRequest_Title_HasMaxLength100()
    {
        var attr = GetStringLength(typeof(CreateShiftPlanRequest), "Title");
        Assert.NotNull(attr);
        Assert.Equal(100, attr.MaximumLength);
    }

    // ── Poll ──────────────────────────────────────────────────────────────────

    [Fact]
    public void CreatePollRequest_Question_HasMaxLength250()
    {
        var attr = GetStringLength(typeof(CreatePollRequest), "Question");
        Assert.NotNull(attr);
        Assert.Equal(250, attr.MaximumLength);
    }

    // ── GEMA ──────────────────────────────────────────────────────────────────

    [Fact]
    public void CreateGemaReportRequest_Title_HasMaxLength200()
    {
        var attr = GetStringLength(typeof(CreateGemaReportRequest), "Title");
        Assert.NotNull(attr);
        Assert.Equal(200, attr.MaximumLength);
    }

    [Fact]
    public void AddGemaReportEntryRequest_Title_HasMaxLength300()
    {
        var attr = GetStringLength(typeof(AddGemaReportEntryRequest), "Title");
        Assert.NotNull(attr);
        Assert.Equal(300, attr.MaximumLength);
    }

    [Fact]
    public void AddGemaReportEntryRequest_Composer_HasMaxLength200()
    {
        var attr = GetStringLength(typeof(AddGemaReportEntryRequest), "Composer");
        Assert.NotNull(attr);
        Assert.Equal(200, attr.MaximumLength);
    }

    // ── Substitute ────────────────────────────────────────────────────────────

    [Fact]
    public void CreateSubstituteAccessRequest_Name_HasMaxLength100()
    {
        var attr = GetStringLength(typeof(CreateSubstituteAccessRequest), "Name");
        Assert.NotNull(attr);
        Assert.Equal(100, attr.MaximumLength);
    }
}
