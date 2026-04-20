using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Sheetstorm.PdfLabeling.Abstractions;
using Sheetstorm.PdfLabeling.Domain;
using Sheetstorm.PdfLabeling.Services;

namespace Sheetstorm.PdfLabeling.Cli;

public class Program
{
    private const string Version = "0.1.0-mvp";

    static async Task<int> Main(string[] args)
    {
        return await MainAsync(args, Console.Out, Console.Error, CancellationToken.None);
    }

    public static async Task<int> MainAsync(string[] args, TextWriter stdout, TextWriter stderr, CancellationToken cancellationToken)
    {
        // Handle --help
        if (args.Length == 0 || args.Contains("--help") || args.Contains("-h"))
        {
            PrintHelp(stdout);
            return 0;
        }

        // Handle --version
        if (args.Contains("--version") || args.Contains("-v"))
        {
            await stdout.WriteLineAsync($"pdflabeler {Version}");
            return 0;
        }

        // Parse arguments
        var (options, error) = ArgumentParser.Parse(args);
        if (error != null || options == null)
        {
            await stderr.WriteLineAsync($"Error: {error}");
            return 1;
        }

        // Setup cancellation
        var cts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        var cancelFileWatcher = options.CancelFile != null
            ? Task.Run(() => WatchCancelFile(options.CancelFile, cts), cts.Token)
            : Task.CompletedTask;

        try
        {
            // Setup DI and run orchestrator
            var services = ConfigureServices(options, stderr);
            using var serviceProvider = services.BuildServiceProvider();

            var orchestrator = serviceProvider.GetRequiredService<IPdfLabelingOrchestrator>();
            
            var job = new LabelingJob(options.SourceDirectory, options.TargetDirectory);
            var results = new List<LabelingResult>();
            
            var progress = new Progress<ProgressUpdate>(async update =>
            {
                // Write progress event for each file
                if (!string.IsNullOrEmpty(update.CurrentFileName))
                {
                    await NdjsonWriter.WriteProgressAsync(stdout, update.CurrentFileName, update.ProcessedCount, update.TotalCount);
                }
            });

            results.AddRange(await orchestrator.LabelBatchAsync(job, progress, cts.Token));

            // Write results
            foreach (var result in results)
            {
                await NdjsonWriter.WriteResultAsync(stdout, result);
            }

            // Write done summary
            var recognized = results.Count(r => r.Status == LabelingStatus.Labeled || r.Status == LabelingStatus.DuplicateResolved);
            var fallback = results.Count(r => r.Status == LabelingStatus.Unrecognized);
            await NdjsonWriter.WriteDoneAsync(stdout, results.Count, recognized, fallback);

            // Check for cancellation
            var cancelled = results.Any(r => r.Status == LabelingStatus.Cancelled);
            return cancelled ? 2 : 0;
        }
        catch (OperationCanceledException)
        {
            // Cancellation is graceful - orchestrator handles it
            await NdjsonWriter.WriteDoneAsync(stdout, 0, 0, 0);
            return 2;
        }
        catch (Exception ex)
        {
            await stderr.WriteLineAsync($"Fatal error: {ex.Message}");
            return 1;
        }
        finally
        {
            cts.Cancel();
            await cancelFileWatcher;
        }
    }

    private static IServiceCollection ConfigureServices(CliOptions options, TextWriter stderr)
    {
        var services = new ServiceCollection();

        // Logging to stderr
        services.AddLogging(builder =>
        {
            builder.AddSimpleConsole(opts =>
            {
                opts.SingleLine = true;
            });
            builder.SetMinimumLevel(LogLevel.Warning);
        });

        // Token provider
        var tokenEnvVar = options.TokenEnv ?? "SHEETSTORM_PAT";
        services.AddSingleton<ITitleRecognizerTokenProvider>(new EnvironmentTokenProvider(tokenEnvVar));

        // Register services from library
        services.AddSingleton<IPdfFirstPageRenderer, PdfFirstPageRenderer>();
        services.AddSingleton<ITitleRecognizer, GitHubModelsTitleRecognizer>();
        services.AddSingleton<IFileNameSanitizer, FileNameSanitizer>();
        services.AddSingleton<IFileTargetResolver, FileTargetResolver>();
        services.AddSingleton<IPdfLabelingOrchestrator, PdfLabelingOrchestrator>();

        return services;
    }

    private static async Task WatchCancelFile(string cancelFilePath, CancellationTokenSource cts)
    {
        while (!cts.Token.IsCancellationRequested)
        {
            if (File.Exists(cancelFilePath))
            {
                cts.Cancel();
                break;
            }
            await Task.Delay(500, cts.Token);
        }
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


