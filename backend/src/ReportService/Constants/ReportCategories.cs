namespace ReportService.Constants;

public record ReportSubcategory(string Code, string Name);

public record ReportCategory(string Code, string Name, IReadOnlyList<ReportSubcategory> Subcategories);

public static class ReportCategories
{
    public static readonly IReadOnlyList<ReportCategory> List = new List<ReportCategory>
    {
        new("ROAD_DAMAGE", "Yol hasarı", new List<ReportSubcategory>
        {
            new("POTHOLE", "Çukur"),
            new("CRACK", "Çatlak veya kırık asfalt"),
            new("MANHOLE", "Rögar kapağı sorunu")
        }),
        new("WATER_LEAK", "Su ve kanalizasyon", new List<ReportSubcategory>
        {
            new("PIPE_LEAK", "Boru patlağı veya su sızıntısı"),
            new("SEWER_OVERFLOW", "Kanalizasyon taşması"),
            new("FLOODING", "Su birikintisi veya baskın"),
            new("BLOCKED_DRAIN", "Tıkalı ızgara")
        }),
        new("LIGHTING", "Aydınlatma", new List<ReportSubcategory>
        {
            new("LIGHT_OUT", "Yanmayan lamba"),
            new("DAMAGED_POLE", "Hasarlı direk"),
            new("EXPOSED_WIRE", "Açıkta kablo")
        }),
        new("WASTE", "Çöp ve temizlik", new List<ReportSubcategory>
        {
            new("GARBAGE_PILE", "Çöp birikintisi"),
            new("ILLEGAL_DUMPING", "Moloz veya kaçak döküm"),
            new("OVERFLOWING_BIN", "Taşan konteyner"),
            new("DAMAGED_BIN", "Hasarlı konteyner")
        }),
        new("SIDEWALK", "Kaldırım", new List<ReportSubcategory>
        {
            new("BROKEN_PAVING", "Kırık veya çökmüş taş"),
            new("CURB_DAMAGE", "Bordür hasarı"),
            new("ACCESS_RAMP", "Engelli rampası sorunu"),
            new("OBSTRUCTION", "Kaldırımı kapatan engel")
        }),
        new("PARK", "Park ve bahçe", new List<ReportSubcategory>
        {
            new("BENCH", "Bank veya oturma alanı"),
            new("PLAYGROUND", "Oyun alanı"),
            new("LANDSCAPING", "Çim ve peyzaj bakımı")
        }),
        new("TREE", "Ağaç", new List<ReportSubcategory>
        {
            new("FALLEN_TREE", "Devrilmiş ağaç veya kırık dal"),
            new("PRUNING", "Budama gerekiyor"),
            new("DEAD_TREE", "Kurumuş ağaç")
        }),
        new("TRAFFIC_SIGN", "Trafik işaretleri", new List<ReportSubcategory>
        {
            new("DAMAGED_SIGN", "Hasarlı veya devrilmiş tabela"),
            new("TRAFFIC_LIGHT", "Trafik ışığı arızası"),
            new("ROAD_MARKING", "Silik yol çizgisi")
        }),
        new("OTHER", "Diğer", new List<ReportSubcategory>
        {
            new("GRAFFITI", "Duvar yazısı")
        })
    };

    public static readonly IReadOnlySet<string> All = List
        .Select(category => category.Code)
        .ToHashSet();

    public static bool IsSubcategoryOf(string categoryCode, string subcategoryCode)
    {
        var category = List.FirstOrDefault(category => category.Code == categoryCode);

        return category != null
            && category.Subcategories.Any(subcategory => subcategory.Code == subcategoryCode);
    }
}
