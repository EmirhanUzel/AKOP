using Microsoft.EntityFrameworkCore;
using ReportService.Data;
using ReportService.Models;

namespace ReportService.Repositories;

public class ReportRepository : IReportRepository
{
    private readonly ReportDbContext _reportDbContext;

    public ReportRepository(ReportDbContext reportDbContext)
    {
        _reportDbContext = reportDbContext;
    }

    public async Task AddAsync(Report report)
    {
        await _reportDbContext.Reports.AddAsync(report);
        await _reportDbContext.SaveChangesAsync();
    } 
    public async Task<List<Report>> GetByCitizenIdAsync (string citizenId)
    {
        return await _reportDbContext.Reports
            .AsNoTracking()
            .Where(report => report.CitizenId == citizenId)
            .OrderByDescending(report => report.CreatedAt)
            .ToListAsync();
    }


}