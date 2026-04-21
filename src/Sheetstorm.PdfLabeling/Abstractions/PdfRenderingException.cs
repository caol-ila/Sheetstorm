namespace Sheetstorm.PdfLabeling.Abstractions;

/// <summary>
/// Exception thrown when PDF rendering fails due to corrupted, encrypted, or otherwise invalid PDF data.
/// </summary>
public class PdfRenderingException : Exception
{
    public PdfRenderingException(string message) : base(message)
    {
    }

    public PdfRenderingException(string message, Exception innerException) : base(message, innerException)
    {
    }
}
