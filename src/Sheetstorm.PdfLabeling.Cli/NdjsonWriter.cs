using System.Text.Json;
using Sheetstorm.PdfLabeling.Domain;

namespace Sheetstorm.PdfLabeling.Cli;

public static class NdjsonWriter
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase
    };

    public static async Task WriteProgressAsync(TextWriter writer, string file, int index, int total)
    {
        var obj = new
        {
            type = "progress",
            file,
            index,
            total
        };
        await WriteLineAsync(writer, obj);
    }

    public static async Task WriteResultAsync(TextWriter writer, LabelingResult result)
    {
        if (result.Status == LabelingStatus.Labeled || result.Status == LabelingStatus.DuplicateResolved)
        {
            var obj = new
            {
                type = "result",
                original = Path.GetFileName(result.SourcePath),
                title = result.RecognizedTitle ?? "",
                confidence = result.Confidence,
                targetPath = result.TargetPath ?? ""
            };
            await WriteLineAsync(writer, obj);
        }
        else if (result.Status == LabelingStatus.Failed)
        {
            var obj = new
            {
                type = "error",
                file = Path.GetFileName(result.SourcePath),
                message = result.Message ?? "Unknown error"
            };
            await WriteLineAsync(writer, obj);
        }
    }

    public static async Task WriteDoneAsync(TextWriter writer, int processed, int recognized, int fallback)
    {
        var obj = new
        {
            type = "done",
            processed,
            recognized,
            fallback
        };
        await WriteLineAsync(writer, obj);
    }

    private static async Task WriteLineAsync(TextWriter writer, object obj)
    {
        var json = JsonSerializer.Serialize(obj, JsonOptions);
        await writer.WriteLineAsync(json);
        await writer.FlushAsync();
    }
}
