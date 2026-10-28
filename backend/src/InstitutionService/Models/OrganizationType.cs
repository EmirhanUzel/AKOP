using System.Text.Json.Serialization;

namespace InstitutionService.Models;

public class OrganizationType
{
    public int Id { get; set; }

    public string Name { get; set; } = "";

    [JsonIgnore]
    public string NormalizedName { get; set; } = "";
}
