
namespace ReportService.Models;

public class Report
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string CitizenId { get; set; } = "";
    public string? Title { get; set; }
    public string Description { get; set; } = "";
    public string? CategoryCode { get; set; }
    public double Latitude {get; set;}
    public double Longitude {get; set;}
    public ReportStatus Status {get;set;} = ReportStatus.Pending;
    public DateTime CreatedAt {get;set;} = DateTime.UtcNow;




}