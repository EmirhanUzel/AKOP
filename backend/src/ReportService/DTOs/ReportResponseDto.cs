namespace ReportService.DTOs;

public class ReportResponseDto
{
    public Guid Id { get; set; }
    public string? Title { get; set; }
    public string Description { get; set; } = "";
    public string? CategoryCode { get; set; }
    public string? SubcategoryCode { get; set; }
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public string? LocationDescription { get; set; }
    public string Status { get; set; } = "";
    public DateTime CreatedAt { get; set; }

    // Göreli adresler; istemci kendi ReportService adresinin önüne ekler
    public List<string> ImageUrls { get; set; } = new();
}
