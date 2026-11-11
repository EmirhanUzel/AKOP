using ReportService.DTOs;

namespace ReportService.Services;

public interface ICategorySuggestionService
{
    bool IsAvailable { get; }

    Task<CategorySuggestionResponseDto> SuggestAsync(CategorySuggestionRequestDto dto);
}
