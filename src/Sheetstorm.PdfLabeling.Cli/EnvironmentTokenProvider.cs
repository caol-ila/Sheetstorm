using Sheetstorm.PdfLabeling.Abstractions;

namespace Sheetstorm.PdfLabeling.Cli;

public sealed class EnvironmentTokenProvider : ITitleRecognizerTokenProvider
{
    private readonly string _environmentVariableName;

    public EnvironmentTokenProvider(string environmentVariableName)
    {
        _environmentVariableName = environmentVariableName ?? throw new ArgumentNullException(nameof(environmentVariableName));
    }

    public ValueTask<string> GetTokenAsync(CancellationToken ct = default)
    {
        var token = Environment.GetEnvironmentVariable(_environmentVariableName);
        if (string.IsNullOrEmpty(token))
        {
            throw new InvalidOperationException($"Environment variable '{_environmentVariableName}' is not set or is empty");
        }
        return ValueTask.FromResult(token);
    }
}
