import 'package:akop_mobile/features/reports/application/draft_controller.dart';
import 'package:akop_mobile/features/reports/application/reports_controller.dart';
import 'package:akop_mobile/features/reports/data/report_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('en çok 5 fotoğraf tutulur', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(draftProvider.notifier).addPhotos(['1', '2', '3', '4']);
    c.read(draftProvider.notifier).addPhotos(['5', '6']);
    expect(c.read(draftProvider).photos, ['1', '2', '3', '4', '5']);
  });

  test('toNewReport boş başlığı null yapar, konum yoksa varsayılanı kullanır', () {
    final n = const ReportDraft(description: '  Çukur var ', title: ' ').toNewReport();
    expect(n.description, 'Çukur var');
    expect(n.title, isNull);
    expect(n.lat, defaultLocation.latitude);
  });

  test('gönderilen ihbar listenin başına eklenir', () async {
    final c = ProviderContainer(overrides: [reportRepositoryProvider.overrideWithValue(FakeReportRepository(delay: Duration.zero))]);
    addTearDown(c.dispose);
    await c.read(reportsProvider.future);
    final r = await c.read(reportsProvider.notifier).create(const ReportDraft(description: 'Yeni sorun').toNewReport());
    expect(c.read(reportsProvider).value!.first.id, r.id);
    expect(r.title, 'Yeni sorun');
  });
}
