using System.Text.Json;

using Microsoft.ML.OnnxRuntime;
using Microsoft.ML.OnnxRuntime.Tensors;

namespace ReportService.Classification;

// ai/scripts/export_onnx.py çıktısını (akop_category.onnx + akop_category.json) çalıştırır
public sealed class OnnxCategoryClassifier : ICategoryClassifier, IDisposable
{
    private readonly InferenceSession? _session;
    private readonly string[] _classes = Array.Empty<string>();
    private readonly string _inputName = "image";

    public OnnxCategoryClassifier(
        IConfiguration configuration,
        IWebHostEnvironment environment,
        ILogger<OnnxCategoryClassifier> logger)
    {
        var configuredDirectory = configuration["CategoryModel:Directory"] ?? "../../../ai/models";

        var directory = Path.GetFullPath(
            Path.Combine(environment.ContentRootPath, configuredDirectory)
        );

        var modelPath = Path.Combine(directory, "akop_category.onnx");
        var metadataPath = Path.Combine(directory, "akop_category.json");

        if (!File.Exists(modelPath) || !File.Exists(metadataPath))
        {
            logger.LogWarning(
                "Kategori modeli bulunamadı ({Directory}); kategori önerisi kapalı. Model ai/scripts/export_onnx.py ile üretilir.",
                directory);
            return;
        }

        using var metadata = JsonDocument.Parse(File.ReadAllText(metadataPath));

        _classes = metadata.RootElement.GetProperty("classes")
            .EnumerateArray()
            .Select(element => element.GetString()!)
            .ToArray();

        _inputName = metadata.RootElement.GetProperty("input").GetString()!;

        _session = new InferenceSession(modelPath);

        logger.LogInformation("Kategori modeli yüklendi: {Model}", modelPath);
    }

    public bool IsAvailable => _session != null;

    public IReadOnlyDictionary<string, float> Classify(Stream imageStream)
    {
        if (_session == null)
        {
            throw new InvalidOperationException("Kategori modeli yüklenmedi.");
        }

        var input = new DenseTensor<float>(
            CategoryImagePreprocessor.Preprocess(imageStream),
            new[] { 1, 3, CategoryImagePreprocessor.ImageSize, CategoryImagePreprocessor.ImageSize }
        );

        // InferenceSession.Run aynı anda birden çok istekten çağrılabilir
        using var results = _session.Run(new[] { NamedOnnxValue.CreateFromTensor(_inputName, input) });

        var probabilities = results[0].AsEnumerable<float>().ToArray();

        return _classes
            .Select((code, index) => (code, probability: probabilities[index]))
            .ToDictionary(item => item.code, item => item.probability);
    }

    public void Dispose()
    {
        _session?.Dispose();
    }
}
