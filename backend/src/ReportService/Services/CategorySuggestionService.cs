using ReportService.Classification;
using ReportService.Constants;
using ReportService.DTOs;
using ReportService.Storage;

namespace ReportService.Services;

public class CategorySuggestionService : ICategorySuggestionService
{
    private const int SuggestionCount = 3;

    private readonly ICategoryClassifier _classifier;

    // Eşikler test setinde ölçüldü:
    // ilk öneri >= 0.5 iken doğruluk %91.5, altında %46
    // doğru kategorinin olasılığı yalnızca %0.9 durumda 0.02'nin altında kaldı
    private readonly double _minConfidence;
    private readonly double _mismatchThreshold;

    public CategorySuggestionService(ICategoryClassifier classifier, IConfiguration configuration)
    {
        _classifier = classifier;
        _minConfidence = configuration.GetValue("CategoryModel:MinConfidence", 0.5);
        _mismatchThreshold = configuration.GetValue("CategoryModel:MismatchThreshold", 0.02);
    }

    public bool IsAvailable => _classifier.IsAvailable;

    public async Task<CategorySuggestionResponseDto> SuggestAsync(CategorySuggestionRequestDto dto)
    {
        var file = dto.File;

        if (file == null || file.Length == 0)
        {
            throw new ArgumentException("Fotoğraf gönderilmelidir.");
        }

        if (file.Length > ReportImageLimits.MaxFileSizeBytes)
        {
            throw new ArgumentException("Fotoğraf en fazla 10 MB olabilir.");
        }

        if (dto.CategoryCode != null && !ReportCategories.All.Contains(dto.CategoryCode))
        {
            throw new ArgumentException("Geçersiz kategori.");
        }

        await using var stream = new MemoryStream();
        await file.CopyToAsync(stream);
        stream.Position = 0;

        var format = await ImageFormatDetector.DetectAsync(stream);

        if (format == null)
        {
            throw new ArgumentException("Yalnızca JPEG, PNG veya WEBP fotoğraf yüklenebilir.");
        }

        if (!format.IsSupported)
        {
            throw new ArgumentException("HEIC fotoğraflar desteklenmiyor; fotoğrafı JPEG olarak gönderin.");
        }

        stream.Position = 0;

        var probabilities = _classifier.Classify(stream);

        var suggestions = probabilities
            .OrderByDescending(item => item.Value)
            .Take(SuggestionCount)
            .Select(item => new CategorySuggestionDto
            {
                Code = item.Key,
                Name = ReportCategories.List.First(category => category.Code == item.Key).Name,
                Confidence = Math.Round(item.Value, 4)
            })
            .ToList();

        var response = new CategorySuggestionResponseDto
        {
            Suggestions = suggestions,
            IsConfident = suggestions[0].Confidence >= _minConfidence
        };

        if (dto.CategoryCode != null)
        {
            var confidence = probabilities[dto.CategoryCode];

            response.SelectedCategory = new SelectedCategoryCheckDto
            {
                Code = dto.CategoryCode,
                Confidence = Math.Round(confidence, 4),
                MatchesImage = confidence >= _mismatchThreshold
            };
        }

        return response;
    }
}
