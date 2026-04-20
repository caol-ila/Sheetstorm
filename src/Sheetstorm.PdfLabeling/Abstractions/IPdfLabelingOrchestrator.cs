using Sheetstorm.PdfLabeling.Domain;

namespace Sheetstorm.PdfLabeling.Abstractions;

public interface IPdfLabelingOrchestrator
{
    Task<IReadOnlyList<LabelingResult>> LabelBatchAsync(LabelingJob job, IProgress<ProgressUpdate>? progress = null, CancellationToken ct = default);
}
