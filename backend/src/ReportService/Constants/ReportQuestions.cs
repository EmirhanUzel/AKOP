namespace ReportService.Constants;

public enum ReportQuestionType
{
    YesNo,
    SingleChoice
}

public record ReportQuestionOption(string Code, string Text);

public record ReportQuestion(
    string Code,
    string Text,
    ReportQuestionType Type,
    IReadOnlyList<ReportQuestionOption> Options);

// Dinamik form: kategori seçilince açılan ek sorular. Hepsi isteğe bağlı; cevaplar ileride önceliklendirmede kullanılacak
public static class ReportQuestions
{
    // Evet/hayır soruları da seçenekli tutulur; böylece her cevap bir seçenek kodu olur
    private static readonly IReadOnlyList<ReportQuestionOption> YesNoOptions = new List<ReportQuestionOption>
    {
        new("YES", "Evet"),
        new("NO", "Hayır")
    };

    public static readonly IReadOnlyDictionary<string, IReadOnlyList<ReportQuestion>> ByCategory =
        new Dictionary<string, IReadOnlyList<ReportQuestion>>
        {
            ["ROAD_DAMAGE"] = new List<ReportQuestion>
            {
                Choice("SIZE", "Sorun ne büyüklükte?",
                    new("SMALL", "Küçük (el büyüklüğü)"),
                    new("MEDIUM", "Orta (araba tekerleği kadar)"),
                    new("LARGE", "Büyük (araç geçemiyor)")),
                YesNo("BLOCKS_TRAFFIC", "Trafiği engelliyor mu?")
            },
            ["WATER_LEAK"] = new List<ReportQuestion>
            {
                YesNo("STILL_FLOWING", "Su akmaya devam ediyor mu?"),
                YesNo("BAD_SMELL", "Kötü koku var mı?")
            },
            ["LIGHTING"] = new List<ReportQuestion>
            {
                Choice("LIGHT_COUNT", "Kaç lamba yanmıyor?",
                    new("ONE", "1"),
                    new("TWO_TO_FIVE", "2–5"),
                    new("MORE_THAN_FIVE", "5'ten fazla")),
                YesNo("ELECTRIC_HAZARD", "Açıkta kablo veya elektrik tehlikesi var mı?")
            },
            ["WASTE"] = new List<ReportQuestion>
            {
                Choice("DURATION", "Ne kadar zamandır orada?",
                    new("TODAY", "Bugün"),
                    new("FEW_DAYS", "Birkaç gün"),
                    new("OVER_A_WEEK", "Bir haftadan fazla")),
                YesNo("BAD_SMELL", "Kötü koku var mı?")
            },
            ["SIDEWALK"] = new List<ReportQuestion>
            {
                YesNo("BLOCKS_PEDESTRIANS", "Yayaların geçişini engelliyor mu?"),
                YesNo("INJURY_RISK", "Düşme veya yaralanma tehlikesi var mı?")
            },
            ["PARK"] = new List<ReportQuestion>
            {
                YesNo("SAFETY_HAZARD", "İnsanlar için tehlike oluşturuyor mu?"),
                YesNo("IN_PLAYGROUND", "Çocuk oyun alanında mı?")
            },
            ["TRAFFIC_SIGN"] = new List<ReportQuestion>
            {
                YesNo("AFFECTS_SAFETY", "Trafik güvenliğini etkiliyor mu?")
            }
        };

    public static IReadOnlyList<ReportQuestion> For(string categoryCode)
    {
        return ByCategory.TryGetValue(categoryCode, out var questions)
            ? questions
            : Array.Empty<ReportQuestion>();
    }

    private static ReportQuestion YesNo(string code, string text)
    {
        return new ReportQuestion(code, text, ReportQuestionType.YesNo, YesNoOptions);
    }

    private static ReportQuestion Choice(string code, string text, params ReportQuestionOption[] options)
    {
        return new ReportQuestion(code, text, ReportQuestionType.SingleChoice, options);
    }
}
