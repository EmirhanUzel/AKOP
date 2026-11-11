# linear_probe_v1_plus_zero_shot

- model: ViT-B-32-quickgelu (openai)
- train_images: 1200
- C: 100.0
- cv_accuracy: 0.7975
- blend: 0.5 linear probe + 0.5 zero-shot
- Fotoğraf: 212 · Doğruluk: **%87.7** · İlk 3'te doğru: %98.6

## Kategori bazında

| Kategori | Fotoğraf | Doğru | Doğruluk |
|---|---|---|---|
| ROAD_DAMAGE | 43 | 39 | %91 |
| WATER_LEAK | 21 | 15 | %71 |
| LIGHTING | 20 | 18 | %90 |
| WASTE | 19 | 19 | %100 |
| SIDEWALK | 20 | 18 | %90 |
| PARK | 34 | 25 | %74 |
| TRAFFIC_SIGN | 30 | 28 | %93 |
| OTHER | 25 | 24 | %96 |

## Karışıklık matrisi (satır: gerçek, sütun: tahmin)

| | ROAD_DAMAGE | WATER_LEAK | LIGHTING | WASTE | SIDEWALK | PARK | TRAFFIC_SIGN | OTHER |
|---|---|---|---|---|---|---|---|---|
| **ROAD_DAMAGE** | 39 | 2 | 1 | 0 | 1 | 0 | 0 | 0 |
| **WATER_LEAK** | 5 | 15 | 0 | 0 | 1 | 0 | 0 | 0 |
| **LIGHTING** | 0 | 1 | 18 | 0 | 0 | 0 | 1 | 0 |
| **WASTE** | 0 | 0 | 0 | 19 | 0 | 0 | 0 | 0 |
| **SIDEWALK** | 1 | 0 | 0 | 1 | 18 | 0 | 0 | 0 |
| **PARK** | 1 | 2 | 1 | 0 | 4 | 25 | 0 | 1 |
| **TRAFFIC_SIGN** | 0 | 0 | 0 | 1 | 0 | 0 | 28 | 1 |
| **OTHER** | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 24 |
