using System.ComponentModel.DataAnnotations;

namespace InstitutionService.DTOs;

public class CreateOrganizationDto
{
    [Required]
    [MaxLength(200)]
    public string Name { get; set; } = "";

    [Range(1, int.MaxValue)]
    public int OrganizationTypeId { get; set; }

    [Required]
    [MaxLength(100)]
    public string City { get; set; } = "";

    [MaxLength(100)]
    public string? District { get; set; }

    [MaxLength(1000)]
    public string? ProfileInfo { get; set; }
}
