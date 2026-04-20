namespace Sheetstorm.PdfLabeling.Cli;

internal class Program
{
    private const string Version = "0.1.0-mvp";

    static async Task<int> Main(string[] args)
    {
        return await MainAsync(args, Console.Out, Console.Error, CancellationToken.None);
    }

    internal static async Task<int> MainAsync(string[] args, TextWriter stdout, TextWriter stderr, CancellationToken cancellationToken)
    {
        if (args.Length == 0 || args.Contains("--help") || args.Contains("-h"))
        {
            PrintHelp(stdout);
            return 0;
        }

        if (args.Contains("--version") || args.Contains("-v"))
        {
            await stdout.WriteLineAsync($"pdflabeler {Version}");
            return 0;
        }

        await stdout.WriteLineAsync("Processing not yet implemented");
        return 0;
    }

    private static void PrintHelp(TextWriter stdout)
    {
        stdout.WriteLine("pdflabeler - Batch PDF labeling using AI title recognition");
        stdout.WriteLine();
        stdout.WriteLine("Usage:");
        stdout.WriteLine("  pdflabeler --source <dir> --target <dir> [options]");
        stdout.WriteLine();
        stdout.WriteLine("Options:");
        stdout.WriteLine("  --source <dir>          Source directory containing PDF files");
        stdout.WriteLine("  --target <dir>          Target directory for labeled PDF files");
        stdout.WriteLine("  --confidence <0.0-1.0>  Minimum confidence threshold (default: 0.6)");
        stdout.WriteLine("  --token-env <varname>   Environment variable containing GitHub PAT");
        stdout.WriteLine("  --cancel-file <path>    Cancellation file path");
        stdout.WriteLine("  --help, -h              Show this help");
        stdout.WriteLine("  --version, -v           Show version");
    }
}

