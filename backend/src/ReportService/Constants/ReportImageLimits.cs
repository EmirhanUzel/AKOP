namespace ReportService.Constants;

public static class ReportImageLimits
{
    public const int MinCount = 1;
    public const int MaxCount = 5;
    public const long MaxFileSizeBytes = 10 * 1024 * 1024;

    // 5 fotoğraf + metin alanları için pay
    public const long MaxRequestSizeBytes = 55 * 1024 * 1024;
}
