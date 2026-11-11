# AKOP — AI Sorun Sınıflandırma

İhbar fotoğrafından sorunun kategorisini öneren modelin geliştirme alanı.
Bu klasördeki Python kodu modeli denemek, ölçmek ve .NET'e taşımak için kullanılır.
Canlı sistemde model ReportService içinde **ONNX Runtime** ile çalışır; Python gerekmez.

## Kategoriler

Mobil uygulama ve ReportService ile aynı kodlar:

| Kod | Ad |
|---|---|
| `ROAD_DAMAGE` | Yol hasarı |
| `WATER_LEAK` | Su arızası |
| `LIGHTING` | Aydınlatma |
| `WASTE` | Çöp ve temizlik |
| `SIDEWALK` | Kaldırım |
| `PARK` | Park ve yeşil alan (ağaçlar dahil) |
| `TRAFFIC_SIGN` | Trafik işaretleri |
| `OTHER` | Diğer |

## Yaklaşım

1. **Zero-shot (ilk prototip):** Önceden eğitilmiş CLIP modeli. Her kategori için metin tarifleri yazılır; fotoğraf en çok benzediği tarifin kategorisine atanır. Eğitim gerektirmez.
2. **Linear probe (iyileştirme):** CLIP'in görsel temsilleri üzerinde, toplanan fotoğraflarla küçük bir sınıflandırıcı eğitilir.
3. **Dışa aktarma:** CLIP'in görsel kodlayıcısı ve linear probe tek ONNX dosyasında birleştirilir (`models/akop_category.onnx`). Girdi: ön işlenmiş fotoğraf `[N,3,224,224]`; çıktı: 8 kategorinin olasılıkları `[N,8]`. Ön işleme ayarları ve sınıf sırası `models/akop_category.json` dosyasında.
4. **Entegrasyon:** ReportService'te `POST /api/Reports/category-suggestions` uç noktası, ilk 3 kategoriyi güven skoruyla döner. Güven düşükse öneri verilmez.

## Klasör yapısı

```text
ai/
├── README.md
├── requirements.txt
├── data/            # Fotoğraflar — Git'e girmez
│   └── test/<KOD>/  # Test seti: her kategori için bir klasör
├── models/          # Linear probe ağırlıkları, ONNX dosyaları — Git'e girmez
├── results/         # Ölçüm sonuçları (doğruluk, karışıklık matrisi) — Git'e girer
└── scripts/         # Değerlendirme ve dışa aktarma betikleri
```

## Kurulum

```bash
cd ai
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Sonuçlar

Test seti: 8 kategoride 212 fotoğraf (SF 311 + Road Issues, elle kontrol edildi). Eğitim seti: 1.200 fotoğraf (kategori başına 150, elle kontrol edilmedi), test setiyle çakışmıyor; testle neredeyse aynı (kosinüs ≥ 0.95) eğitim fotoğrafı bulunmadı.

| Deneme | Yaklaşım | Test fotoğrafı | Doğruluk | İlk 3'te doğru |
|---|---|---|---|---|
| `zero_shot_v1` | Zero-shot, 9 kategori | 230 | %73.5 | %92.2 |
| `zero_shot_v2_park_merged` | Zero-shot, ağaç parka birleşti | 230 | %76.5 | %93.5 |
| `zero_shot_v3_cleaned` | Zero-shot, yanlış etiketli 18 fotoğraf çıkarıldı | 212 | %79.7 | %93.9 |
| **`linear_probe_v1`** | **CLIP + lojistik regresyon (C=100, 5 katlı çapraz doğrulamayla seçildi)** | **212** | **%88.7** | **%99.1** |
| `linear_probe_v1_plus_zero_shot` | Yarı yarıya karışım | 212 | %87.7 | %98.6 |
| `onnx_v1` | `linear_probe_v1`'in ONNX hali (ONNX Runtime, PyTorch'suz ön işleme) | 212 | %88.7 | %99.1 |

Notlar:
- `zero_shot_v3_cleaned` için test setinden çıkarılan 18 fotoğraf hatalı tahminlere bakılarak bulundu (etiketi yanlış ya da belirsiz olanlar, havadan çekilmiş otopark görselleri). Bu, sonucu bir miktar iyimser gösterebilir; temizlik öncesi sonuçlar da saklandı.
- C değeri yalnızca eğitim setinde seçildi. Daha dar aralıkla (C=10) testte %91.5 ölçüldü; test setine göre seçim yapılmadığı için asıl sonuç %88.7.
- En zayıf kategoriler: su arızası (%76, ıslak asfalt yol hasarıyla karışıyor), park (%79, kaldırımdaki ağaç dipleri kaldırımla karışıyor), kaldırım (%80).
- Fotoğrafların çoğu ABD'den. Türkiye fotoğraflarıyla tekrar ölçülmeli.

## Betikler

```bash
cd ai
.venv/bin/python scripts/evaluate.py --name zero_shot_deneme          # zero-shot ölçüm (prompts.json)
.venv/bin/python scripts/download_train.py --per-category 150         # eğitim fotoğrafları
cd scripts && ../.venv/bin/python train_linear_probe.py               # linear probe eğitimi + ölçüm
.venv/bin/python scripts/predict.py foto1.jpg foto2.jpg               # tek fotoğraf için ilk 3 öneri
.venv/bin/python scripts/export_onnx.py                               # ONNX'e aktarma + PyTorch ile karşılaştırma
```

Linear probe ağırlıkları `models/linear_probe.json`, ONNX modeli `models/akop_category.onnx` (~350 MB) dosyasına yazılır (Git dışı).

### Ön işleme (ReportService ile birebir aynı olmalı)

1. EXIF yönüne göre döndür, RGB'ye çevir.
2. Kısa kenarı 224 piksele getir; uzun kenar `int(224 · uzun / kısa)` (aşağı yuvarlanır). Bicubic.
3. Ortadan 224×224 kırp; başlangıç `round((kenar - 224) / 2)`.
4. Pikselleri 255'e böl, kanal bazında `(x - mean) / std` uygula, `[1,3,224,224]` (RGB, CHW) tensöre çevir.

Uzun kenarın yuvarlanması bile sonucu değiştirir: ilk denemede en yakına yuvarlandığında 22 fotoğrafın 2'sinde tahmin farklı çıktı.

## Veri kaynakları

Kullanılan her veri kaynağı lisansıyla birlikte buraya yazılır. Lisans, kaynağın kendi sayfasından doğrulanmadan veri kullanılmaz.

| Kaynak | Kategoriler | Lisans | Doğrulandı mı | Kullanıldı mı |
|---|---|---|---|---|
| [Road Issues Detection Dataset (Hugging Face)](https://huggingface.co/datasets/Programmer-RD-AI/road-issues-detection-dataset) | ROAD_DAMAGE, TRAFFIC_SIGN, OTHER | CC0-1.0 | Evet (veri seti kartı) | Evet: ROAD_DAMAGE 22, TRAFFIC_SIGN 10, OTHER 20 |
| [SF 311 Cases (DataSF)](https://data.sf.gov/City-Infrastructure/311-Cases/vw6y-z8j6) | Hepsi (8 kategori) | Kayıt verisi PDDL; fotoğraflar vatandaşlara ait, ayrı lisans yok | Evet (kayıt verisi) | Evet: 176 fotoğraf, yalnızca yerel test |
| [Urban Issues Dataset (Kaggle)](https://www.kaggle.com/datasets/akinduhiman/urban-issues-dataset) | ROAD_DAMAGE, WASTE, OTHER | CC0 | Hayır | Hayır |
| [Chennai Streetlight Dataset](https://arxiv.org/pdf/2407.01117) | LIGHTING | ? | Hayır | Hayır |
| [Broken_Sidewalk (Roboflow)](https://universe.roboflow.com/helmet-phtvn/broken_sidewalk) | SIDEWALK | CC BY 4.0 | Hayır | Hayır |
| Ekip tarafından çekilen fotoğraflar | Hepsi, özellikle WATER_LEAK, PARK, SIDEWALK | Ekibe ait | — | Hayır |

Notlar:
- **Road Issues veri seti hakkında:** Fotoğraflar sabit tohumla (42) rastgele seçildi, liste `data/test/manifest_hf.json` içinde. Eşleştirme: Pothole + Damaged Road → `ROAD_DAMAGE`; Broken Road Sign → `TRAFFIC_SIGN`; Vandalism + Illegal Parking → `OTHER`. Elle kontrolde şunlar ayıklandı (`data/rejected/`):
  - "Damaged Road" klasöründe hız tümsekleri, bir reklam görseli ve önceden çoğaltılmış (siyah karelerle kapatılmış, döndürülmüş) görseller var.
  - "Littering Garbage" klasörü çoğunlukla çöp görünmeyen Street View kareleri; `WASTE` için kullanılmadı.
  - Görsellerin bir kısmı gri tonlamalı ve döndürülmüş; veri seti önceden eğitim için çoğaltılmış.
- **SF 311 hakkında:** San Francisco belediyesine vatandaşların gönderdiği gerçek ihbar fotoğrafları. Kategori başına 30 fotoğraf sabit tohumla (42) seçildi, liste `data/test/manifest_sf.json` içinde. Elle kontrolde ekran görüntüleri, içeriği belli olmayan kareler, başka kategoriye ait olanlar ve yüzü görünen kişiler ayıklandı. `PARK` için SF'deki "landscaping" (9 fotoğraf) ve "damaged_tree" (25 fotoğraf) kayıtları kullanıldı; ağaçlar ayrı kategori değil, park ve yeşil alanın parçası. Fotoğraflar repoya konmaz, paylaşılmaz.
- Aynı görseller birden fazla veri setinde bulunabilir (Road Issues ve Urban Issues benzer içerikte). Aynı fotoğraf hem eğitime hem teste düşmemeli.
- Test setinde Türkiye'den, ekibin kendi çektiği fotoğraflar mutlaka bulunmalı.
