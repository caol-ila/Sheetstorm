namespace Sheetstorm.PdfLabeling.Abstractions;

public interface IFileTargetResolver
{
    string Resolve(string targetDirectory, string desiredFileName, string extension);
}
