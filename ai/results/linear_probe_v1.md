# linear_probe_v1

- model: ViT-B-32-quickgelu (openai)
- train_images: 1200
- C: 100.0
- cv_accuracy: 0.7975
- Fotoğraf: 212 · Doğruluk: **%88.7** · İlk 3'te doğru: %99.1

## Kategori bazında

| Kategori | Fotoğraf | Doğru | Doğruluk |
|---|---|---|---|
| ROAD_DAMAGE | 43 | 38 | %88 |
| WATER_LEAK | 21 | 16 | %76 |
| LIGHTING | 20 | 19 | %95 |
| WASTE | 19 | 19 | %100 |
| SIDEWALK | 20 | 16 | %80 |
| PARK | 34 | 27 | %79 |
| TRAFFIC_SIGN | 30 | 28 | %93 |
| OTHER | 25 | 25 | %100 |

## Karışıklık matrisi (satır: gerçek, sütun: tahmin)

| | ROAD_DAMAGE | WATER_LEAK | LIGHTING | WASTE | SIDEWALK | PARK | TRAFFIC_SIGN | OTHER |
|---|---|---|---|---|---|---|---|---|
| **ROAD_DAMAGE** | 38 | 2 | 1 | 0 | 2 | 0 | 0 | 0 |
| **WATER_LEAK** | 4 | 16 | 0 | 0 | 1 | 0 | 0 | 0 |
| **LIGHTING** | 0 | 1 | 19 | 0 | 0 | 0 | 0 | 0 |
| **WASTE** | 0 | 0 | 0 | 19 | 0 | 0 | 0 | 0 |
| **SIDEWALK** | 2 | 1 | 0 | 1 | 16 | 0 | 0 | 0 |
| **PARK** | 0 | 1 | 2 | 1 | 3 | 27 | 0 | 0 |
| **TRAFFIC_SIGN** | 0 | 0 | 0 | 1 | 1 | 0 | 28 | 0 |
| **OTHER** | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 25 |
