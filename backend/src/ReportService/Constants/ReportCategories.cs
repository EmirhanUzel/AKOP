namespace ReportService.Constants;

public static class ReportCategories
{
    public static readonly IReadOnlySet<string> All = new HashSet<string>
    {
        "ROAD_DAMAGE",
        "WATER_LEAK",
        "LIGHTING",
        "WASTE",
        "SIDEWALK",
        "PARK",
        "OTHER"
    };
}
