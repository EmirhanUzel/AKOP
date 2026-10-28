import 'package:akop_mobile/features/reports/application/draft_controller.dart';
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
}
