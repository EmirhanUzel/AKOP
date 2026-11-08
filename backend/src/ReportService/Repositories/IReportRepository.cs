using ReportService.Models;

namespace ReportService.Repositories;

public interface IReportRepository
{
    Task AddAsync(Report report);
    Task<List<Report>> GetByCitizenIdAsync (string citizenId);
    Task<Report?> GetCitizenReportAsync(Guid reportId, string citizenId);
    Task<ReportImage?> GetCitizenImageAsync(Guid reportId, Guid imageId, string citizenId);
}