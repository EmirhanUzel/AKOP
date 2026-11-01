import '../domain/report.dart';

abstract interface class ReportRepository {
  /// Giriş yapan vatandaşın ihbarları, yeniden eskiye.
  Future<List<Report>> myReports();
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
}
