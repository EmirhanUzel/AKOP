namespace ReportService.Storage;

public interface IFileStorage
{
    Task SaveAsync(string key, Stream content);

    Task<Stream?> OpenReadAsync(string key);

    Task DeleteAsync(string key);
}
