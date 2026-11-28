namespace ReportService.DTOs;

public class CategoryDto
{
    public string Code { get; set; } = "";
    public string Name { get; set; } = "";
    public List<SubcategoryDto> Subcategories { get; set; } = new();
    public List<QuestionDto> Questions { get; set; } = new();
}

public class SubcategoryDto
{
    public string Code { get; set; } = "";
    public string Name { get; set; } = "";
}

public class QuestionDto
{
    public string Code { get; set; } = "";
    public string Text { get; set; } = "";

    // "YesNo" ya da "SingleChoice"; istemci soruyu buna göre çizer
    public string Type { get; set; } = "";
    public List<QuestionOptionDto> Options { get; set; } = new();
}

public class QuestionOptionDto
{
    public string Code { get; set; } = "";
    public string Text { get; set; } = "";
}
