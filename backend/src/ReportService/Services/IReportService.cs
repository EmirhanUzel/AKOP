using ReportService.DTOs;


namespace ReportService.Services;


public interface IReportService
{
    Task<ReportResponseDto> CreateAsync(CreateReportDto dto, string citizenId);
    Task<List<ReportResponseDto>> GetMineAsync (string citizenId);
}