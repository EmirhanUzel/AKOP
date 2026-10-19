import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/report_repository.dart';
import '../domain/report.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) => FakeReportRepository());

class ReportsController extends AsyncNotifier<List<Report>> {
  @override
  Future<List<Report>> build() => ref.read(reportRepositoryProvider).list();

  /// Çek-yenile: iskelet göstermeden listeyi tazeler.
  Future<void> refresh() async {
    state = await AsyncValue.guard(ref.read(reportRepositoryProvider).list);
  }

  Future<Report> create(NewReport n) async {
    final r = await ref.read(reportRepositoryProvider).create(n);
    state = AsyncData([r, ...?state.value]);
    return r;
  }

  Future<void> confirm(String id, {required bool resolved, String? comment}) async {
    final r = await ref.read(reportRepositoryProvider).confirm(id, resolved: resolved, comment: comment);
    _replace(r);
  }

  Future<void> provideInfo(String id, {String? text, List<String> photos = const []}) async {
    final r = await ref.read(reportRepositoryProvider).provideInfo(id, text: text, photos: photos);
    _replace(r);
  }

  void _replace(Report r) {
    state = AsyncData([for (final x in state.value ?? const <Report>[]) x.id == r.id ? r : x]);
  }
}

final reportsProvider = AsyncNotifierProvider<ReportsController, List<Report>>(ReportsController.new);

/// Detay ekranı için: listeden id ile bulur.
final reportByIdProvider = Provider.family<Report?, String>((ref, id) {
  final list = ref.watch(reportsProvider).value ?? const <Report>[];
  for (final r in list) {
    if (r.id == id) return r;
  }
  return null;
});
