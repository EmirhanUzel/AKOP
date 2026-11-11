namespace ReportService.DTOs;

public class CategorySuggestionRequestDto
{
    public IFormFile? File { get; set; }

    // İsteğe bağlı: kullanıcının seçtiği kategori; fotoğrafla uyumu kontrol edilir
    public string? CategoryCode { get; set; }
}

public class CategorySuggestionResponseDto
{
    // Olasılığa göre ilk 3 kategori
    public List<CategorySuggestionDto> Suggestions { get; set; } = new();

    // İlk önerinin güveni eşiğin üstünde mi; değilse mobil kategoriyi otomatik seçmemeli
    public bool IsConfident { get; set; }

    // CategoryCode gönderildiyse dolu
    public SelectedCategoryCheckDto? SelectedCategory { get; set; }
}

public class CategorySuggestionDto
{
    public string Code { get; set; } = "";
    public string Name { get; set; } = "";
    public double Confidence { get; set; }
}

public class SelectedCategoryCheckDto
{
    public string Code { get; set; } = "";
    public double Confidence { get; set; }

    // false ise "Fotoğraf bu kategoriye benzemiyor, emin misiniz?" uyarısı gösterilebilir
    public bool MatchesImage { get; set; }
}
