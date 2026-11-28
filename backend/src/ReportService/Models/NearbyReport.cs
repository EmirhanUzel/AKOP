namespace ReportService.Models;

// Yakınlık sorgusunun sonucu: ihbar ve aranan noktaya uzaklığı
public class NearbyReport
{
    public Report Report { get; set; } = null!;
    public double DistanceMeters { get; set; }
}
