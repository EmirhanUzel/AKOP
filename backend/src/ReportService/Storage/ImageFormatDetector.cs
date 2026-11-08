namespace ReportService.Storage;

public record ImageFormat(string ContentType, string Extension, bool IsSupported = true);

// Dosya adına ve istemcinin bildirdiği türe güvenilmez; ilk baytlara bakılır
public static class ImageFormatDetector
{
    private static readonly ImageFormat Jpeg = new("image/jpeg", ".jpg");
    private static readonly ImageFormat Png = new("image/png", ".png");
    private static readonly ImageFormat Webp = new("image/webp", ".webp");
    private static readonly ImageFormat Heic = new("image/heic", ".heic", IsSupported: false);

    private static readonly HashSet<string> HeicBrands = new()
    {
        "heic", "heix", "hevc", "hevx", "heim", "heis", "mif1", "msf1"
    };

    public static async Task<ImageFormat?> DetectAsync(Stream stream)
    {
        var header = new byte[12];
        var read = await stream.ReadAtLeastAsync(header, header.Length, throwOnEndOfStream: false);

        if (read >= 3
            && header[0] == 0xFF && header[1] == 0xD8 && header[2] == 0xFF)
        {
            return Jpeg;
        }

        if (read >= 8
            && header[0] == 0x89 && header[1] == 0x50 && header[2] == 0x4E && header[3] == 0x47
            && header[4] == 0x0D && header[5] == 0x0A && header[6] == 0x1A && header[7] == 0x0A)
        {
            return Png;
        }

        // RIFF....WEBP
        if (read >= 12
            && header[0] == 0x52 && header[1] == 0x49 && header[2] == 0x46 && header[3] == 0x46
            && header[8] == 0x57 && header[9] == 0x45 && header[10] == 0x42 && header[11] == 0x50)
        {
            return Webp;
        }

        // HEIC/HEIF: ....ftyp + marka (heic, mif1 ...). Tanınır ama kabul edilmez,
        // tarayıcılar gösteremediği için mobil JPEG'e çevirip göndermeli
        if (read >= 12
            && header[4] == 0x66 && header[5] == 0x74 && header[6] == 0x79 && header[7] == 0x70
            && HeicBrands.Contains(System.Text.Encoding.ASCII.GetString(header, 8, 4)))
        {
            return Heic;
        }

        return null;
    }
}
