import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/api_config.dart';
import '../../auth/application/auth_controller.dart';
import '../data/api_report_repository.dart';
import '../data/report_repository.dart';
import '../domain/report.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) => ApiReportRepository(ref.watch(apiDioProvider), reportApiBaseUrl));

/// Otomatik yeniden deneme kapalı: hata ekranındaki "Tekrar dene" düğmesi bu işi yapar.
final myReportsProvider = FutureProvider.autoDispose<List<Report>>(
  (ref) => ref.watch(reportRepositoryProvider).myReports(),
  retry: (_, _) => null,
);

/// Bir ihbar fotoğrafının baytları (adres [Report.imageUrls]'ten). Hata ekranı yerinde "yüklenemedi" gösterir.
final reportImageProvider = FutureProvider.autoDispose.family<Uint8List, String>(
  (ref, path) => ref.watch(reportRepositoryProvider).image(path),
  retry: (_, _) => null,
);
