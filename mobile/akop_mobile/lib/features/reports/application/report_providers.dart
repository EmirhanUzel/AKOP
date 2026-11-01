import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/report_repository.dart';
import '../domain/report.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) => FakeReportRepository());

/// Otomatik yeniden deneme kapalı: hata ekranındaki "Tekrar dene" düğmesi bu işi yapar.
final myReportsProvider = FutureProvider.autoDispose<List<Report>>(
  (ref) => ref.watch(reportRepositoryProvider).myReports(),
  retry: (_, _) => null,
);
