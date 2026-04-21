using System.Text;
using System.Text.RegularExpressions;
using Sheetstorm.PdfLabeling.Abstractions;

namespace Sheetstorm.PdfLabeling.Services;

public sealed class FileNameSanitizer : IFileNameSanitizer
{
    private static readonly HashSet<string> ReservedNames = new(StringComparer.OrdinalIgnoreCase)
    {
        "CON", "PRN", "AUX", "NUL",
        "COM1", "COM2", "COM3", "COM4", "COM5", "COM6", "COM7", "COM8", "COM9",
        "LPT1", "LPT2", "LPT3", "LPT4", "LPT5", "LPT6", "LPT7", "LPT8", "LPT9"
    };

    private static readonly char[] InvalidChars = { '<', '>', ':', '"', '/', '\\', '|', '?', '*' };

    public string Sanitize(string rawTitle)
    {
        if (string.IsNullOrWhiteSpace(rawTitle))
        {
            return "unbenannt";
        }

        var result = rawTitle;

        // Remove control characters
        result = RemoveControlCharacters(result);

        // Replace invalid Windows filename characters with underscore
        foreach (var invalidChar in InvalidChars)
        {
            result = result.Replace(invalidChar, '_');
        }

        // Collapse multiple spaces to single space
        result = Regex.Replace(result, @"\s+", " ");

        // Trim leading/trailing whitespace
        result = result.Trim();

        // Trim trailing dots and spaces
        result = result.TrimEnd('.', ' ');

        // Truncate to 150 characters
        if (result.Length > 150)
        {
            result = result.Substring(0, 150);
            // Re-trim trailing dots and spaces after truncation
            result = result.TrimEnd('.', ' ');
        }

        // Handle empty result after processing
        if (string.IsNullOrWhiteSpace(result))
        {
            return "unbenannt";
        }

        // Handle reserved Windows names
        if (ReservedNames.Contains(result))
        {
            result = "_" + result;
        }

        return result;
    }

    private static string RemoveControlCharacters(string input)
    {
        var sb = new StringBuilder(input.Length);
        foreach (var c in input)
        {
            if (!char.IsControl(c))
            {
                sb.Append(c);
            }
        }
        return sb.ToString();
    }
}
