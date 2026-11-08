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
            .Include(report => report.Images)
            .Where(report => report.CitizenId == citizenId)
            .OrderByDescending(report => report.CreatedAt)
            .ToListAsync();
    }

    // İhbar yalnızca sahibi olan vatandaşa döner; değilse null
    public async Task<Report?> GetCitizenReportAsync(Guid reportId, string citizenId)
    {
        return await _reportDbContext.Reports
            .AsNoTracking()
            .Include(report => report.Images)
            .FirstOrDefaultAsync(report =>
                report.Id == reportId &&
                report.CitizenId == citizenId);
    }

    // Fotoğraf yalnızca ihbarın sahibi olan vatandaşa döner; değilse null
    public async Task<ReportImage?> GetCitizenImageAsync(Guid reportId, Guid imageId, string citizenId)
    {
        return await _reportDbContext.ReportImages
            .AsNoTracking()
            .FirstOrDefaultAsync(image =>
                image.Id == imageId &&
                image.ReportId == reportId &&
                image.Report.CitizenId == citizenId);
    }


}