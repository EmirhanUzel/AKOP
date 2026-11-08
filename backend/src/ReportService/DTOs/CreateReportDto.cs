using System.ComponentModel.DataAnnotations;

namespace ReportService.DTOs;

public class CreateReportDto
{
    [MaxLength(120)]
    public string? Title {get; set;}

    [Required]
    [MaxLength(2000)]
    public string Description {get; set;} ="";

    [MaxLength(50)]
    public string? CategoryCode {get; set;}

    [Required]
    [Range(-90,90)]
    public double? Latitude {get;set;}

    [Required]
    [Range(-180,180)]
    public double? Longitude {get;set;}

    [MaxLength(300)]
    public string? LocationDescription {get; set;}

    // Formdaki "files" alanı; sayı, boyut ve tür kontrolü service'te
    public List<IFormFile> Files { get; set; } = new();

}