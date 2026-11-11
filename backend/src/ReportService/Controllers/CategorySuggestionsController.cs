using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

using ReportService.Constants;
using ReportService.DTOs;
using ReportService.Services;

namespace ReportService.Controllers;

// Fotoğraftan kategori önerisi; ihbar kaydetmez, fotoğrafı saklamaz
[ApiController]
[Route("api/Reports/category-suggestions")]
[Authorize]
public class CategorySuggestionsController : ControllerBase
{
    private readonly ICategorySuggestionService _categorySuggestionService;

    public CategorySuggestionsController(ICategorySuggestionService categorySuggestionService)
    {
        _categorySuggestionService = categorySuggestionService;
    }

    [HttpPost]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(ReportImageLimits.MaxFileSizeBytes + 1024 * 1024)]
    [RequestFormLimits(MultipartBodyLengthLimit = ReportImageLimits.MaxFileSizeBytes + 1024 * 1024)]
    public async Task<IActionResult> Suggest([FromForm] CategorySuggestionRequestDto dto)
    {
        // Model sunucuda yoksa ihbar akışı yine çalışır; mobil kategoriyi kullanıcıya seçtirir
        if (!_categorySuggestionService.IsAvailable)
        {
            return StatusCode(StatusCodes.Status503ServiceUnavailable, "Kategori önerisi şu anda kullanılamıyor.");
        }

        try
        {
            return Ok(await _categorySuggestionService.SuggestAsync(dto));
        }
        catch (ArgumentException exception)
        {
            return BadRequest(exception.Message);
        }
    }
}
