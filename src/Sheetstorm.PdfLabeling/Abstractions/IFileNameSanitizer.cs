namespace Sheetstorm.PdfLabeling.Abstractions;

public interface IFileNameSanitizer
{
    string Sanitize(string rawTitle);
}
