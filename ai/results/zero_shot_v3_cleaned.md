# zero_shot_v3_cleaned

- Model: ViT-B-32-quickgelu (openai) · Cihaz: cuda
- Fotoğraf: 212 · Doğruluk: **%79.7** · İlk 3'te doğru: %93.9
- Fotoğraf başına süre: 18.7 ms

## Kategori bazında

| Kategori | Fotoğraf | Doğru | Doğruluk |
|---|---|---|---|
| ROAD_DAMAGE | 43 | 38 | %88 |
| WATER_LEAK | 21 | 14 | %67 |
| LIGHTING | 20 | 16 | %80 |
| WASTE | 19 | 18 | %95 |
| SIDEWALK | 20 | 18 | %90 |
| PARK | 34 | 19 | %56 |
| TRAFFIC_SIGN | 30 | 27 | %90 |
| OTHER | 25 | 19 | %76 |

## Karışıklık matrisi (satır: gerçek, sütun: tahmin)

| | ROAD_DAMAGE | WATER_LEAK | LIGHTING | WASTE | SIDEWALK | PARK | TRAFFIC_SIGN | OTHER |
|---|---|---|---|---|---|---|---|---|
| **ROAD_DAMAGE** | 38 | 2 | 1 | 0 | 1 | 0 | 0 | 1 |
| **WATER_LEAK** | 5 | 14 | 0 | 1 | 1 | 0 | 0 | 0 |
| **LIGHTING** | 0 | 1 | 16 | 0 | 0 | 0 | 3 | 0 |
| **WASTE** | 0 | 0 | 0 | 18 | 0 | 0 | 0 | 1 |
| **SIDEWALK** | 1 | 0 | 0 | 0 | 18 | 0 | 0 | 1 |
| **PARK** | 3 | 2 | 0 | 2 | 5 | 19 | 1 | 2 |
| **TRAFFIC_SIGN** | 0 | 0 | 0 | 1 | 1 | 0 | 27 | 1 |
| **OTHER** | 0 | 0 | 0 | 3 | 2 | 0 | 1 | 19 |
