using Sheetstorm.PdfLabeling.Domain;

namespace Sheetstorm.PdfLabeling.Abstractions;

public interface IProgressReporter
{
    void Report(ProgressUpdate update);
}
