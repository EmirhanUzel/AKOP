using SkiaSharp;

namespace ReportService.Classification;

// Modelin eğitildiği Python ön işlemesiyle (open_clip → torchvision → PIL) birebir aynı olmalı;
// tek piksellik fark bile tahmini değiştirebiliyor (ai/README.md, "Ön işleme")
public static class CategoryImagePreprocessor
{
    public const int ImageSize = 224;

    // Çok büyük boyutlu görseller belleği doldurmasın (ör. 8000×6000 = 48 MP)
    private const long MaxPixels = 50_000_000;

    private static readonly float[] Mean = { 0.48145466f, 0.4578275f, 0.40821073f };
    private static readonly float[] Std = { 0.26862954f, 0.26130258f, 0.27577711f };

    // Çıktı: [3, 224, 224] RGB, kanal kanal (CHW) düzleştirilmiş
    public static float[] Preprocess(Stream imageStream)
    {
        var (pixels, width, height) = DecodeRgb(imageStream);

        // Kısa kenar 224; uzun kenar torchvision gibi aşağı yuvarlanır
        var shortSide = Math.Min(width, height);
        var longSide = Math.Max(width, height);
        var newLong = (int)(ImageSize * (double)longSide / shortSide);

        var (newWidth, newHeight) = width <= height
            ? (ImageSize, newLong)
            : (newLong, ImageSize);

        // PIL gibi önce yatay, sonra dikey
        pixels = PilBicubic.ResizeHorizontal(pixels, width, height, newWidth);
        pixels = PilBicubic.ResizeVertical(pixels, newWidth, height, newHeight);

        // Ortadan kırpma; Math.Round, Python'daki round gibi yarımları çifte yuvarlar
        var left = (int)Math.Round((newWidth - ImageSize) / 2.0);
        var top = (int)Math.Round((newHeight - ImageSize) / 2.0);

        const int plane = ImageSize * ImageSize;
        var tensor = new float[3 * plane];

        for (var y = 0; y < ImageSize; y++)
        {
            for (var x = 0; x < ImageSize; x++)
            {
                var source = ((top + y) * newWidth + left + x) * 3;
                var index = y * ImageSize + x;

                for (var channel = 0; channel < 3; channel++)
                {
                    tensor[channel * plane + index] =
                        (pixels[source + channel] / 255f - Mean[channel]) / Std[channel];
                }
            }
        }

        return tensor;
    }

    // Fotoğrafı çözer, EXIF yönüne göre döndürür ve RGB bayt dizisine çevirir (saydamlık atılır)
    private static (byte[] Pixels, int Width, int Height) DecodeRgb(Stream imageStream)
    {
        using var codec = SKCodec.Create(imageStream)
            ?? throw new ArgumentException("Fotoğraf okunamadı.");

        var info = codec.Info;

        if ((long)info.Width * info.Height > MaxPixels)
        {
            throw new ArgumentException("Fotoğrafın çözünürlüğü çok yüksek.");
        }

        using var bitmap = new SKBitmap(
            new SKImageInfo(info.Width, info.Height, SKColorType.Rgba8888, SKAlphaType.Unpremul));

        // Yarım kalmış dosya da reddedilir: eksik kısım gri dolar ve model yanlış ama emin bir tahmin verir
        if (codec.GetPixels(bitmap.Info, bitmap.GetPixels()) != SKCodecResult.Success)
        {
            throw new ArgumentException("Fotoğraf okunamadı.");
        }

        var source = bitmap.GetPixelSpan();
        var sourceWidth = info.Width;
        var sourceHeight = info.Height;

        // 5–8 numaralı yönlerde fotoğraf 90° döner; genişlik ve yükseklik yer değiştirir
        var swapsSides = codec.EncodedOrigin is SKEncodedOrigin.LeftTop or SKEncodedOrigin.RightTop
            or SKEncodedOrigin.RightBottom or SKEncodedOrigin.LeftBottom;

        var width = swapsSides ? sourceHeight : sourceWidth;
        var height = swapsSides ? sourceWidth : sourceHeight;
        var pixels = new byte[width * height * 3];

        for (var y = 0; y < height; y++)
        {
            for (var x = 0; x < width; x++)
            {
                var (sx, sy) = codec.EncodedOrigin switch
                {
                    SKEncodedOrigin.TopRight => (sourceWidth - 1 - x, y),
                    SKEncodedOrigin.BottomRight => (sourceWidth - 1 - x, sourceHeight - 1 - y),
                    SKEncodedOrigin.BottomLeft => (x, sourceHeight - 1 - y),
                    SKEncodedOrigin.LeftTop => (y, x),
                    SKEncodedOrigin.RightTop => (y, sourceHeight - 1 - x),
                    SKEncodedOrigin.RightBottom => (sourceWidth - 1 - y, sourceHeight - 1 - x),
                    SKEncodedOrigin.LeftBottom => (sourceWidth - 1 - y, x),
                    _ => (x, y)
                };

                var from = (sy * sourceWidth + sx) * 4;
                var to = (y * width + x) * 3;

                pixels[to] = source[from];
                pixels[to + 1] = source[from + 1];
                pixels[to + 2] = source[from + 2];
            }
        }

        return (pixels, width, height);
    }
}
