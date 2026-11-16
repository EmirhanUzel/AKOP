import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/api_config.dart';
import '../../auth/application/auth_controller.dart';
import '../data/api_report_repository.dart';
import '../data/report_repository.dart';
import '../domain/report.dart';
import '../domain/report_category.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) => ApiReportRepository(ref.watch(apiDioProvider), reportApiBaseUrl));

/// Otomatik yeniden deneme kapalı: hata ekranındaki "Tekrar dene" düğmesi bu işi yapar.
final myReportsProvider = FutureProvider.autoDispose<List<Report>>(
  (ref) => ref.watch(reportRepositoryProvider).myReports(),
  retry: (_, _) => null,
);

/// Kategoriler oturum boyunca değişmez; hata olursa Riverpod kendisi yeniden dener.
final reportCategoriesProvider = FutureProvider<List<ReportCategory>>((ref) => ref.watch(reportRepositoryProvider).categories());

/// Fotoğraftan kategori önerisi ([category] verilirse uyum kontrolü). Hata ya da 503'te null: öneri gösterilmez, akış sürer.
final categorySuggestionProvider = FutureProvider.autoDispose.family<CategorySuggestion?, ({String photo, String? category})>(
  (ref, q) => ref
      .watch(reportRepositoryProvider)
      .suggestCategory(q.photo, categoryCode: q.category)
      .then<CategorySuggestion?>((s) => s, onError: (_) => null),
  retry: (_, _) => null,
);

/// Bir ihbar fotoğrafının baytları (adres [Report.imageUrls]'ten). Hata ekranı yerinde "yüklenemedi" gösterir.
final reportImageProvider = FutureProvider.autoDispose.family<Uint8List, String>(
  (ref, path) => ref.watch(reportRepositoryProvider).image(path),
  retry: (_, _) => null,
);
