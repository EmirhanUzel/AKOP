import 'dart:typed_data';

import '../../auth/data/auth_repository.dart';
import '../domain/new_report.dart';
import '../domain/report.dart';
import '../domain/report_category.dart';

/// Sunucu ihbarı reddetti (ör. fotoğraf kuralı); [message] kullanıcıya gösterilir.
class ReportRejected implements Exception {
  ReportRejected(this.message);

  final String message;
}

abstract interface class ReportRepository {
  /// Giriş yapan vatandaşın ihbarları, yeniden eskiye.
  Future<List<Report>> myReports();

  /// İhbarı fotoğraflarıyla tek istekte oluşturur: ya hep birlikte oluşur ya hiç.
  Future<void> create(NewReport report);

  /// [Report.imageUrls] içindeki bir fotoğrafın baytları.
  Future<Uint8List> image(String path);

  /// Kategoriler ve alt kategorileri.
  Future<List<ReportCategory>> categories();

  /// Fotoğraftan kategori önerisi; [categoryCode] verilirse fotoğrafla uyumu da döner.
  Future<CategorySuggestion> suggestCategory(String photo, {String? categoryCode});
}

/// ReportService API'si hazır olana kadar kullanılan sahte sürüm: tek örnek ihbar döner.
/// Gerçek sürüm aynı arayüzü uygular, ekranlar değişmez.
class FakeReportRepository implements ReportRepository {
  FakeReportRepository({this.reports, this.delay = Duration.zero});

  /// Verilmezse tek örnek ihbar döner.
  final List<Report>? reports;
  final Duration delay;

  @override
  Future<List<Report>> myReports() async {
    await Future<void>.delayed(delay);
    return reports ??
        [
          Report(
            id: 'ornek-1',
            title: 'Kaldırımda çukur var',
            status: ReportStatus.inProgress,
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
            locationText: 'Çankaya, Ankara',
            categoryCode: 'SIDEWALK',
          ),
        ];
  }

  @override
  Future<void> create(NewReport report) => Future<void>.delayed(delay);

  @override
  Future<Uint8List> image(String path) async => Uint8List(0);

  @override
  Future<List<ReportCategory>> categories() async => const [
        ReportCategory('SIDEWALK', 'Kaldırım'),
        ReportCategory('PARK', 'Park ve yeşil alan', [ReportSubcategory('BENCH', 'Bank veya oturma alanı')]),
        ReportCategory('OTHER', 'Diğer'),
      ];

  /// Öneri servisi kapalıymış gibi davranır; ihbar akışı öneri olmadan sürer.
  @override
  Future<CategorySuggestion> suggestCategory(String photo, {String? categoryCode}) async => throw NetworkFailure();
}
