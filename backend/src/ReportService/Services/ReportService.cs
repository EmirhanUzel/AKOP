using ReportService.Repositories;
using ReportService.Models;
using ReportService.DTOs;

namespace ReportService.Services;

public class ReportService : IReportService
{
    private readonly IReportRepository _reportRepository;
    public ReportService(IReportRepository reportRepository)
    {
        _reportRepository = reportRepository;
    }

    public async Task<ReportResponseDto> CreateAsync(CreateReportDto dto, string citizenId)
    {
        var title = string.IsNullOrWhiteSpace(dto.Title)
            ? null
            : dto.Title.Trim();
        var categoryCode = string.IsNullOrWhiteSpace(dto.CategoryCode)
            ? null
            : dto.CategoryCode.Trim();
        var locationDescription = string.IsNullOrWhiteSpace(dto.LocationDescription)
            ? null
            : dto.LocationDescription.Trim();

        var report = new Report
        {
            CitizenId = citizenId,
            Title = title,
            Description = dto.Description.Trim(),
            CategoryCode = categoryCode,
            Latitude = dto.Latitude!.Value,
            Longitude = dto.Longitude!.Value,
            LocationDescription = locationDescription
        };

        await _reportRepository.AddAsync(report);

        return MapToResponse(report);
    }

    public async Task<List<ReportResponseDto>> GetMineAsync (string citizenId)
    {
        var results = await _reportRepository.GetByCitizenIdAsync(citizenId);
        var responses = new List<ReportResponseDto>();
        
        foreach(var report in results)
        {
            responses.Add(MapToResponse(report));
        }
        return responses;
    }


    private static ReportResponseDto MapToResponse(Report report)
    {
        return new ReportResponseDto
        {
            Id = report.Id,
            Title = report.Title,
            Description = report.Description,
            CategoryCode = report.CategoryCode,
            Latitude = report.Latitude,
            Longitude = report.Longitude,
            LocationDescription = report.LocationDescription,
            Status = report.Status.ToString(),
            CreatedAt = report.CreatedAt
        };
    }


}