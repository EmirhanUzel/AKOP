using System.ComponentModel.DataAnnotations;

namespace InstitutionService.DTOs;

public class CreateOrganizationTypeDto
{
    [Required]
    [MaxLength(100)]
    public string Name { get; set; } = "";
}