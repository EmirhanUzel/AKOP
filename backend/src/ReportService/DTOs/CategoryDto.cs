namespace ReportService.DTOs;

public class CategoryDto
{
    public string Code { get; set; } = "";
    public string Name { get; set; } = "";
    public List<SubcategoryDto> Subcategories { get; set; } = new();
}

public class SubcategoryDto
{
    public string Code { get; set; } = "";
    public string Name { get; set; } = "";
}
