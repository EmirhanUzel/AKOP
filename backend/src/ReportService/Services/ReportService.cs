using ReportService.Constants;
using ReportService.Repositories;
using ReportService.Models;
using ReportService.DTOs;
using ReportService.Storage;

namespace ReportService.Services;

public class ReportService : IReportService
{
    private readonly IReportRepository _reportRepository;
    private readonly IFileStorage _fileStorage;

    public ReportService(IReportRepository reportRepository, IFileStorage fileStorage)
    {
        _reportRepository = reportRepository;
        _fileStorage = fileStorage;
    }

    public async Task<ReportResponseDto> CreateAsync(CreateReportDto dto, string citizenId)
    {
        var title = string.IsNullOrWhiteSpace(dto.Title)
            ? null
            : dto.Title.Trim();
        var categoryCode = string.IsNullOrWhiteSpace(dto.CategoryCode)
            ? null
            : dto.CategoryCode.Trim();

        if (categoryCode != null && !ReportCategories.All.Contains(categoryCode))
        {
            throw new ArgumentException("Geçersiz kategori kodu.");
        }

        var locationDescription = string.IsNullOrWhiteSpace(dto.LocationDescription)
            ? null
            : dto.LocationDescription.Trim();

        var formats = await ValidateImagesAsync(dto.Files);

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

        var savedKeys = new List<string>();

        try
        {
            for (var i = 0; i < dto.Files.Count; i++)
            {
                var file = dto.Files[i];
                var format = formats[i];
                var key = $"reports/{report.Id}/{Guid.NewGuid()}{format.Extension}";

                await using (var stream = file.OpenReadStream())
                {
                    await _fileStorage.SaveAsync(key, stream);
                }

                savedKeys.Add(key);

                report.Images.Add(new ReportImage
                {
                    StorageKey = key,
                    ContentType = format.ContentType,
                    SizeBytes = file.Length
                });
            }

            await _reportRepository.AddAsync(report);
        }
        catch
        {
            // Kayıt tamamlanamadıysa diske yazılan dosyalar sahipsiz kalmasın
            foreach (var key in savedKeys)
            {
                await _fileStorage.DeleteAsync(key);
            }

            throw;
        }

        return MapToResponse(report);
    }

    // Hiçbir dosya diske yazılmadan önce hepsi kontrol edilir
    private static async Task<List<ImageFormat>> ValidateImagesAsync(List<IFormFile> files)
    {
        if (files.Count < ReportImageLimits.MinCount || files.Count > ReportImageLimits.MaxCount)
        {
            throw new ArgumentException(
                $"İhbara {ReportImageLimits.MinCount} ile {ReportImageLimits.MaxCount} arasında fotoğraf eklenmelidir.");
        }

        var formats = new List<ImageFormat>();

        foreach (var file in files)
        {
            if (file.Length == 0 || file.Length > ReportImageLimits.MaxFileSizeBytes)
            {
                throw new ArgumentException("Her fotoğraf en fazla 10 MB olabilir.");
            }

            await using var stream = file.OpenReadStream();
            var format = await ImageFormatDetector.DetectAsync(stream);

            if (format == null)
            {
                throw new ArgumentException("Yalnızca JPEG, PNG veya WEBP fotoğraf yüklenebilir.");
            }

            if (!format.IsSupported)
            {
                throw new ArgumentException("HEIC fotoğraflar desteklenmiyor; fotoğrafı JPEG olarak gönderin.");
            }

            formats.Add(format);
        }

        return formats;
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

    public async Task<ReportResponseDto?> GetMineByIdAsync(Guid reportId, string citizenId)
    {
        var report = await _reportRepository.GetCitizenReportAsync(reportId, citizenId);

        if (report == null)
        {
            return null;
        }

        return MapToResponse(report);
    }

    public async Task<ReportImageFile?> GetImageAsync(Guid reportId, Guid imageId, string citizenId)
    {
        var image = await _reportRepository.GetCitizenImageAsync(reportId, imageId, citizenId);

        if (image == null)
        {
            return null;
        }

        var stream = await _fileStorage.OpenReadAsync(image.StorageKey);

        if (stream == null)
        {
            return null;
        }

        return new ReportImageFile(stream, image.ContentType);
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
            CreatedAt = report.CreatedAt,
            ImageUrls = report.Images
                .OrderBy(image => image.CreatedAt)
                .Select(image => $"/api/Reports/{report.Id}/images/{image.Id}")
                .ToList()
        };
    }


}