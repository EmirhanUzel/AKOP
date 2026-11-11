namespace ReportService.Classification;

public interface ICategoryClassifier
{
    // Model dosyası bulunamadıysa false; servis yine çalışır, yalnızca öneri verilmez
    bool IsAvailable { get; }

    // Kategori kodu → olasılık (toplamı 1)
    IReadOnlyDictionary<string, float> Classify(Stream imageStream);
}
