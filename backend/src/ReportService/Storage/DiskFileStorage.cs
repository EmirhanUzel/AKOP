namespace ReportService.Storage;

public class DiskFileStorage : IFileStorage
{
    private readonly string _rootPath;

    public DiskFileStorage(IConfiguration configuration, IWebHostEnvironment environment)
    {
        var configuredPath = configuration["Storage:RootPath"] ?? "App_Data/report-images";

        _rootPath = Path.GetFullPath(
            Path.Combine(environment.ContentRootPath, configuredPath)
        );

        Directory.CreateDirectory(_rootPath);
    }

    public async Task SaveAsync(string key, Stream content)
    {
        var fullPath = GetFullPath(key);

        Directory.CreateDirectory(Path.GetDirectoryName(fullPath)!);

        // FileMode.CreateNew: aynı anahtarla var olan dosyanın üzerine yazılmaz
        await using var file = new FileStream(fullPath, FileMode.CreateNew, FileAccess.Write);
        await content.CopyToAsync(file);
    }

    public Task<Stream?> OpenReadAsync(string key)
    {
        var fullPath = GetFullPath(key);

        if (!File.Exists(fullPath))
        {
            return Task.FromResult<Stream?>(null);
        }

        Stream stream = new FileStream(fullPath, FileMode.Open, FileAccess.Read, FileShare.Read);

        return Task.FromResult<Stream?>(stream);
    }

    public Task DeleteAsync(string key)
    {
        var fullPath = GetFullPath(key);

        if (File.Exists(fullPath))
        {
            File.Delete(fullPath);
        }

        return Task.CompletedTask;
    }

    // Anahtar "../" gibi parçalarla kök klasörün dışına çıkamaz
    private string GetFullPath(string key)
    {
        var fullPath = Path.GetFullPath(Path.Combine(_rootPath, key));

        if (!fullPath.StartsWith(_rootPath + Path.DirectorySeparatorChar, StringComparison.Ordinal))
        {
            throw new ArgumentException("Geçersiz dosya anahtarı.");
        }

        return fullPath;
    }
}
