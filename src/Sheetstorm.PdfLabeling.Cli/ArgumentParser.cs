namespace Sheetstorm.PdfLabeling.Cli;

public static class ArgumentParser
{
    public static (CliOptions? options, string? error) Parse(string[] args)
    {
        string? source = null;
        string? target = null;
        double confidence = 0.6;
        string? tokenEnv = null;
        string? cancelFile = null;

        for (int i = 0; i < args.Length; i++)
        {
            var arg = args[i];
            
            switch (arg)
            {
                case "--source":
                    if (i + 1 >= args.Length || args[i + 1].StartsWith("--")) 
                        return (null, "Missing value for --source");
                    source = args[++i];
                    break;
                    
                case "--target":
                    if (i + 1 >= args.Length || args[i + 1].StartsWith("--")) 
                        return (null, "Missing value for --target");
                    target = args[++i];
                    break;
                    
                case "--confidence":
                    if (i + 1 >= args.Length || args[i + 1].StartsWith("--")) 
                        return (null, "Missing value for --confidence");
                    var valueStr = args[++i];
                    if (!double.TryParse(valueStr, System.Globalization.NumberStyles.Float, System.Globalization.CultureInfo.InvariantCulture, out confidence))
                        return (null, "Invalid value for --confidence, expected number between 0.0 and 1.0");
                    if (confidence < 0.0 || confidence > 1.0)
                        return (null, "--confidence must be between 0.0 and 1.0");
                    break;
                    
                case "--token-env":
                    if (i + 1 >= args.Length || args[i + 1].StartsWith("--")) 
                        return (null, "Missing value for --token-env");
                    tokenEnv = args[++i];
                    break;
                    
                case "--cancel-file":
                    if (i + 1 >= args.Length || args[i + 1].StartsWith("--")) 
                        return (null, "Missing value for --cancel-file");
                    cancelFile = args[++i];
                    break;
                    
                default:
                    return (null, $"Unknown argument: {arg}");
            }
        }

        if (source == null) return (null, "Missing required argument: --source");
        if (target == null) return (null, "Missing required argument: --target");

        return (new CliOptions(source, target, confidence, tokenEnv, cancelFile), null);
    }
}
