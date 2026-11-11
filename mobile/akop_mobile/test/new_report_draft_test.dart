import 'package:akop_mobile/features/reports/application/draft_controller.dart';
import 'package:akop_mobile/features/reports/presentation/new_report/location_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('en çok 5 fotoğraf tutulur', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(draftProvider.notifier).addPhotos(['1', '2', '3', '4']);
    c.read(draftProvider.notifier).addPhotos(['5', '6']);
    expect(c.read(draftProvider).photos, ['1', '2', '3', '4', '5']);
  });

  test('kategori değişince alt kategori temizlenir', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final d = c.read(draftProvider.notifier)
      ..setCategory('PARK')
      ..setSubcategory('BENCH');
    expect(c.read(draftProvider).subcategoryCode, 'BENCH');
    d.setCategory('PARK');
    expect(c.read(draftProvider).subcategoryCode, 'BENCH');
    d.setCategory('SIDEWALK');
    expect(c.read(draftProvider).subcategoryCode, isNull);
  });

  test('önerilen kategori fotoğraflar silinince kalkar, kullanıcının seçtiği kalır', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final d = c.read(draftProvider.notifier)
      ..addPhotos(['a'])
      ..setCategory('ROAD_DAMAGE', auto: true);
    expect(c.read(draftProvider).categoryAuto, isTrue);
    d.removePhoto(0);
    expect(c.read(draftProvider).categoryCode, isNull);

    d
      ..addPhotos(['b'])
      ..setCategory('PARK', auto: true)
      ..setCategory('PARK'); // kullanıcı aynı kategoriyi onayladı
    expect(c.read(draftProvider).categoryAuto, isFalse);
    d.removePhoto(0);
    expect(c.read(draftProvider).categoryCode, 'PARK');
  });

  test('toNewReport boş başlığı null yapar, seçilen konumu aktarır', () {
    final n = const ReportDraft(description: '  Çukur var ', title: ' ', location: LatLng(39.92, 32.85)).toNewReport();
    expect(n.description, 'Çukur var');
    expect(n.title, isNull);
    expect(n.lat, 39.92);
    expect(n.lng, 32.85);
  });

  testWidgets('konum seçilmeden Devam kapalı, seçilince açılır', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: LocationStep())));
    await tester.pump(const Duration(milliseconds: 200)); // konum izni eklentisi testte yok: reddedilmiş sayılır
    FilledButton next() => tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Devam'));
    expect(next().onPressed, isNull);
    expect(find.text('Henüz seçilmedi'), findsOneWidget);

    ProviderScope.containerOf(tester.element(find.byType(LocationStep))).read(draftProvider.notifier).setLocation(const LatLng(39.92, 32.85));
    await tester.pump();
    expect(next().onPressed, isNotNull);
  });
}
