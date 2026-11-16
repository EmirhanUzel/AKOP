import 'package:akop_mobile/features/auth/data/auth_repository.dart';
import 'package:akop_mobile/features/reports/application/draft_controller.dart';
import 'package:akop_mobile/features/reports/application/report_providers.dart';
import 'package:akop_mobile/features/reports/data/report_repository.dart';
import 'package:akop_mobile/features/reports/domain/report_category.dart';
import 'package:akop_mobile/features/reports/presentation/new_report/detail_step.dart';
import 'package:akop_mobile/features/reports/presentation/new_report/photo_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Kategoriler: Kaldırım, Park ve yeşil alan (Bank alt kategorisi), Diğer.
class _Suggesting extends FakeReportRepository {
  _Suggesting({this.fail = false, this.confident = false});

  final bool fail;
  final bool confident;
  final asked = <String?>[];

  @override
  Future<CategorySuggestion> suggestCategory(String photo, {String? categoryCode}) async {
    asked.add(categoryCode);
    if (fail) throw NetworkFailure();
    return CategorySuggestion(
      suggestions: const [CategoryGuess('SIDEWALK', 'Kaldırım', 0.4), CategoryGuess('PARK', 'Park ve yeşil alan', 0.3)],
      isConfident: confident,
      matchesImage: categoryCode == null ? null : categoryCode == 'PARK',
    );
  }
}

/// 'a.jpg' için emin öneri (Yol hasarı), diğer fotoğraflar için emin olmayan öneri.
class _ByPhoto extends FakeReportRepository {
  @override
  Future<CategorySuggestion> suggestCategory(String photo, {String? categoryCode}) async => CategorySuggestion(
        suggestions: const [CategoryGuess('ROAD_DAMAGE', 'Yol hasarı', 0.9), CategoryGuess('PARK', 'Park ve yeşil alan', 0.05)],
        isConfident: photo == 'a.jpg',
      );
}

Future<ProviderContainer> _open(WidgetTester tester, ReportRepository repo) async {
  tester.view.physicalSize = const Size(390 * 3, 1400 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [reportRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: DetailStep()),
    ),
  );
  final c = ProviderScope.containerOf(tester.element(find.byType(DetailStep)));
  c.read(draftProvider.notifier).addPhotos(['p.jpg']);
  await tester.pumpAndSettle();
  return c;
}

void main() {
  testWidgets('emin değilse öneriler çip olarak gelir, seçilince alt kategori açılır', (tester) async {
    final repo = _Suggesting();
    final c = await _open(tester, repo);
    expect(c.read(draftProvider).categoryCode, isNull); // emin değil: otomatik seçilmez
    expect(find.widgetWithText(ChoiceChip, 'Kaldırım'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Park ve yeşil alan'));
    await tester.pumpAndSettle();
    expect(c.read(draftProvider).categoryCode, 'PARK');
    expect(find.text('Alt kategori seçin'), findsOneWidget);
    expect(repo.asked, [null, 'PARK']); // ilk öneri değil: uyum sorulur
    expect(find.textContaining('benzemiyor'), findsNothing); // uyuyor: uyarı yok

    await tester.tap(find.widgetWithText(ChoiceChip, 'Kaldırım'));
    await tester.pumpAndSettle();
    expect(repo.asked, [null, 'PARK']); // ilk öneri: yeniden sorulmaz
  });

  testWidgets('önerilerin dışında seçim uyum sorar, uymuyorsa yalnızca uyarır', (tester) async {
    final repo = _Suggesting();
    final c = await _open(tester, repo);
    c.read(draftProvider.notifier).setCategory('OTHER');
    await tester.pumpAndSettle();
    expect(repo.asked, [null, 'OTHER']);
    expect(find.text('Fotoğraf bu kategoriye benzemiyor, emin misiniz?'), findsOneWidget);
    expect(c.read(draftProvider).categoryCode, 'OTHER'); // engellemez
  });

  testWidgets('emin öneri: "önerildi" yalnızca önerilen kategori seçiliyken yazar', (tester) async {
    final c = await _open(tester, _Suggesting(confident: true));
    const caption = 'Fotoğrafa göre önerildi, değiştirebilirsiniz.';
    c.read(draftProvider.notifier).setCategory('SIDEWALK');
    await tester.pumpAndSettle();
    expect(find.text(caption), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);

    c.read(draftProvider.notifier).setCategory('OTHER');
    await tester.pumpAndSettle();
    expect(find.text(caption), findsNothing);
    expect(find.text('Fotoğraf bu kategoriye benzemiyor, emin misiniz?'), findsOneWidget);
  });

  testWidgets('öneri servisi hata verirse normal kategori seçimi kalır', (tester) async {
    await _open(tester, _Suggesting(fail: true));
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.text('Boş bırakırsanız sistem sizin için önerir.'), findsOneWidget);
    expect(find.text('Kategori seçin'), findsOneWidget);
  });

  testWidgets('otomatik kategori ilk fotoğraf değişince yenilenir, kullanıcının seçimi korunur', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [reportRepositoryProvider.overrideWithValue(_ByPhoto())],
      child: const MaterialApp(home: PhotoStep()),
    ));
    final c = ProviderScope.containerOf(tester.element(find.byType(PhotoStep)));
    final d = c.read(draftProvider.notifier);
    String? category() => c.read(draftProvider).categoryCode;

    d.addPhotos(['a.jpg', 'b.jpg']);
    await tester.pump();
    await tester.pump();
    expect(category(), 'ROAD_DAMAGE'); // emin: otomatik seçildi

    d.removePhoto(0); // ilk fotoğraf artık b: emin öneri yok
    await tester.pump();
    await tester.pump();
    expect(category(), isNull);

    d.setCategory('PARK'); // kullanıcı seçti
    d.addPhotos(['a.jpg']);
    d.removePhoto(0); // ilk fotoğraf a: emin öneri var ama kullanıcının seçimi kalır
    await tester.pump();
    await tester.pump();
    expect(category(), 'PARK');
  });
}
