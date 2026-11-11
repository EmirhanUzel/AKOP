import 'package:flutter/material.dart';

class ReportSubcategory {
  const ReportSubcategory(this.code, this.name);
  final String code;
  final String name;
}

/// Liste GET /api/Reports/categories ile gelir; uygulamada yalnızca simgeler tutulur.
class ReportCategory {
  const ReportCategory(this.code, this.name, [this.subcategories = const []]);
  final String code;
  final String name;
  final List<ReportSubcategory> subcategories;

  IconData get icon => _icons[code] ?? Icons.more_horiz;
}

const _icons = {
  'ROAD_DAMAGE': Icons.warning_amber_outlined,
  'WATER_LEAK': Icons.water_drop_outlined,
  'LIGHTING': Icons.lightbulb_outline,
  'WASTE': Icons.delete_outline,
  'SIDEWALK': Icons.directions_walk,
  'PARK': Icons.park_outlined,
  'TRAFFIC_SIGN': Icons.traffic_outlined,
};

ReportCategory? categoryOf(List<ReportCategory>? categories, String? code) {
  for (final c in categories ?? const <ReportCategory>[]) {
    if (c.code == code) return c;
  }
  return null;
}

class CategoryGuess {
  const CategoryGuess(this.code, this.name, this.confidence);
  final String code;
  final String name;
  final double confidence;
}

/// POST /api/Reports/category-suggestions yanıtı.
class CategorySuggestion {
  const CategorySuggestion({required this.suggestions, required this.isConfident, this.matchesImage});

  /// En olası 3 kategori, yüksekten düşüğe.
  final List<CategoryGuess> suggestions;

  /// İlk öneri yeterince güçlü: otomatik seçilebilir.
  final bool isConfident;

  /// Yalnızca kategori koduyla sorulduğunda dolu; false ise fotoğraf o kategoriye benzemiyor.
  final bool? matchesImage;
}
