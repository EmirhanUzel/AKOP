# zero_shot_v1

- Model: ViT-B-32-quickgelu (openai) · Cihaz: cuda
- Fotoğraf: 230 · Doğruluk: **%73.5** · İlk 3'te doğru: %92.2
- Fotoğraf başına süre: 19.3 ms

## Kategori bazında

| Kategori | Fotoğraf | Doğru | Doğruluk |
|---|---|---|---|
| ROAD_DAMAGE | 44 | 38 | %86 |
| WATER_LEAK | 23 | 13 | %57 |
| LIGHTING | 21 | 16 | %76 |
| WASTE | 19 | 17 | %89 |
| SIDEWALK | 23 | 18 | %78 |
| PARK | 9 | 1 | %11 |
| TREE | 25 | 13 | %52 |
| TRAFFIC_SIGN | 30 | 27 | %90 |
| OTHER | 36 | 26 | %72 |

## Karışıklık matrisi (satır: gerçek, sütun: tahmin)

| | ROAD_DAMAGE | WATER_LEAK | LIGHTING | WASTE | SIDEWALK | PARK | TREE | TRAFFIC_SIGN | OTHER |
|---|---|---|---|---|---|---|---|---|---|
| **ROAD_DAMAGE** | 38 | 3 | 1 | 0 | 1 | 0 | 0 | 0 | 1 |
| **WATER_LEAK** | 5 | 13 | 0 | 2 | 1 | 2 | 0 | 0 | 0 |
| **LIGHTING** | 0 | 1 | 16 | 0 | 0 | 0 | 0 | 3 | 1 |
| **WASTE** | 0 | 0 | 0 | 17 | 0 | 1 | 0 | 0 | 1 |
| **SIDEWALK** | 1 | 1 | 0 | 2 | 18 | 0 | 0 | 0 | 1 |
| **PARK** | 2 | 1 | 0 | 0 | 5 | 1 | 0 | 0 | 0 |
| **TREE** | 1 | 1 | 0 | 3 | 0 | 4 | 13 | 1 | 2 |
| **TRAFFIC_SIGN** | 0 | 0 | 0 | 1 | 1 | 0 | 0 | 27 | 1 |
| **OTHER** | 2 | 0 | 0 | 3 | 2 | 1 | 0 | 2 | 26 |
