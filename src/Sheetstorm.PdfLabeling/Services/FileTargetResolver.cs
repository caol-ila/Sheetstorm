using Sheetstorm.PdfLabeling.Abstractions;

namespace Sheetstorm.PdfLabeling.Services;

public sealed class FileTargetResolver : IFileTargetResolver
{
    public string Resolve(string targetDirectory, string desiredFileName, string extension)
    {
        // Validate directory exists
        if (!Directory.Exists(targetDirectory))
        {
            throw new DirectoryNotFoundException($"Target directory not found: {targetDirectory}");
        }

        // Normalize extension - ensure it has a leading dot
        var normalizedExtension = extension.StartsWith(".") ? extension : "." + extension;

        // Build base file path
        var baseFileName = desiredFileName + normalizedExtension;
        var basePath = Path.Combine(targetDirectory, baseFileName);

        // Check if file exists (case-insensitive on Windows)
        if (!FileExists(basePath))
        {
            return basePath;
        }

        // File exists, find first available suffix
        for (int suffix = 2; suffix < int.MaxValue; suffix++)
        {
            var candidateFileName = $"{desiredFileName} ({suffix}){normalizedExtension}";
            var candidatePath = Path.Combine(targetDirectory, candidateFileName);

            if (!FileExists(candidatePath))
            {
                return candidatePath;
            }
        }

        // This should never happen in practice
        throw new InvalidOperationException("Could not find available file name");
    }

    private static bool FileExists(string path)
    {
        if (!OperatingSystem.IsWindows())
        {
            return File.Exists(path);
        }

        // On Windows, perform case-insensitive check
        var directory = Path.GetDirectoryName(path);
        var fileName = Path.GetFileName(path);

        if (string.IsNullOrEmpty(directory) || string.IsNullOrEmpty(fileName))
        {
            return File.Exists(path);
        }

        if (!Directory.Exists(directory))
        {
            return false;
        }

        return Directory.GetFiles(directory)
            .Select(Path.GetFileName)
            .Any(f => string.Equals(f, fileName, StringComparison.OrdinalIgnoreCase));
    }
}
