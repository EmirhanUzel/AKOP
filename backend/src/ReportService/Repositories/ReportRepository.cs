using Microsoft.EntityFrameworkCore;
using NetTopologySuite.Geometries;

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

    // PostGIS: IsWithinDistance → ST_DWithin, Distance → ST_Distance; geography kolonunda ikisi de metre
    public async Task<List<NearbyReport>> GetNearbyOpenAsync(Point point, double radiusMeters, string? categoryCode, int limit)
    {
        var query = _reportDbContext.Reports
            .AsNoTracking()
            .Where(report =>
                report.Status != ReportStatus.Resolved &&
                report.Location.IsWithinDistance(point, radiusMeters));

        if (categoryCode != null)
        {
            query = query.Where(report => report.CategoryCode == categoryCode);
        }

        return await query
            .Select(report => new NearbyReport
            {
                Report = report,
                DistanceMeters = report.Location.Distance(point)
            })
            .OrderBy(nearby => nearby.DistanceMeters)
            .Take(limit)
            .ToListAsync();
    }


}