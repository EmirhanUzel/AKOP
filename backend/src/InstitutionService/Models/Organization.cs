using System.Text.Json.Serialization;

namespace InstitutionService.Models;

public class Organization
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Name { get; set; } = "";

    [JsonIgnore]
    public string NormalizedName { get; set; } = "";

    public int OrganizationTypeId { get; set; }
    public OrganizationType OrganizationType { get; set; } = null!;

    public string City { get; set; } = "";
    public string? ProfileInfo { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
