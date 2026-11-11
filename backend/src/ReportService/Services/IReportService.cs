using ReportService.DTOs;


namespace ReportService.Services;


public interface IReportService
{
    Task<ReportResponseDto> CreateAsync(CreateReportDto dto, string citizenId);
    Task<List<ReportResponseDto>> GetMineAsync (string citizenId);
    Task<ReportResponseDto?> GetMineByIdAsync(Guid reportId, string citizenId);
    List<CategoryDto> GetCategories();
    Task<ReportImageFile?> GetImageAsync(Guid reportId, Guid imageId, string citizenId);
}