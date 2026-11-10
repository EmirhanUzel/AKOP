namespace InstitutionService.DTOs;

public class OrganizationResponseDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = "";
    public int OrganizationTypeId { get; set; }
    public string OrganizationTypeName { get; set; } = "";
    public string City { get; set; } = "";
    public string? District { get; set; }
    public string? ProfileInfo { get; set; }
    public DateTime CreatedAt { get; set; }
}
