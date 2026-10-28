import 'package:flutter/material.dart';

class ReportCategory {
  const ReportCategory(this.code, this.name, this.icon);
  final String code;
  final String name;
  final IconData icon;
}

/// Örnek kodlar; gerçek sözlük GET /service-categories ile gelecek.
const reportCategories = [
  ReportCategory('ROAD_DAMAGE', 'Yol hasarı', Icons.warning_amber_outlined),
  ReportCategory('WATER_LEAK', 'Su arızası', Icons.water_drop_outlined),
  ReportCategory('LIGHTING', 'Aydınlatma', Icons.lightbulb_outline),
  ReportCategory('WASTE', 'Çöp ve temizlik', Icons.delete_outline),
  ReportCategory('SIDEWALK', 'Kaldırım', Icons.directions_walk),
  ReportCategory('PARK', 'Park ve bahçe', Icons.park_outlined),
  ReportCategory('OTHER', 'Diğer', Icons.more_horiz),
];

ReportCategory? categoryOf(String? code) {
  for (final c in reportCategories) {
    if (c.code == code) return c;
  }
  return null;
}
