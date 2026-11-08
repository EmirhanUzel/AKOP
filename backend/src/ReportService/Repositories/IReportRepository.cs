using ReportService.Models;

namespace ReportService.Repositories;

public interface IReportRepository
{
    Task AddAsync(Report report);
    Task<List<Report>> GetByCitizenIdAsync (string citizenId);
}