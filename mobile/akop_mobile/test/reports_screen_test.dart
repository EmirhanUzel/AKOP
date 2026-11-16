import 'dart:typed_data';

import 'package:akop_mobile/app.dart';
import 'package:akop_mobile/features/auth/application/auth_controller.dart';
import 'package:akop_mobile/features/auth/data/auth_repository.dart';
import 'package:akop_mobile/features/reports/application/report_providers.dart';
import 'package:akop_mobile/features/reports/data/report_repository.dart';
import 'package:akop_mobile/features/reports/domain/new_report.dart';
import 'package:akop_mobile/features/reports/domain/report.dart';
import 'package:akop_mobile/features/reports/presentation/report_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

class _FailingRepository extends FakeReportRepository {
  int failures = 1;

  @override
  Future<List<Report>> myReports() async {
    if (failures-- > 0) throw Exception('sunucu yok');
    return FakeReportRepository().myReports();
  }

  @override
  Future<void> create(NewReport report) async {}

  @override
  Future<Uint8List> image(String path) async => Uint8List(0);
}

Future<void> _pumpHome(WidgetTester tester, ReportRepository reports) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository(delay: Duration.zero)),
        reportRepositoryProvider.overrideWithValue(reports),
      ],
      child: const AkopApp(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).at(0), 'citizen@akop.test');
  await tester.enterText(find.byType(TextFormField).at(1), '123456');
  await tester.tap(find.text('Giriş yap'));
  await tester.pumpAndSettle();
}

/// Çip satırı yatay kayar ve tembel yüklenir: ekran dışındaki çipi önce görünür yapıp dokunur.
Future<void> _tapChip(WidgetTester tester, String label) async {
  if (find.text(label).evaluate().isEmpty) {
    await tester.drag(find.byType(ListView).first, const Offset(800, 0)); // başa kaydır
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(find.text(label));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

/// Test yazı tipi (Ahem) çok geniş olduğundan RenderFlex taşmalarını yok sayar.
void testApp(String name, Future<void> Function(WidgetTester) body) {
  testWidgets(name, (tester) async {
    final original = FlutterError.onError;
    FlutterError.onError = (d) {
      if (!d.exceptionAsString().contains('overflowed')) original?.call(d);
    };
    try {
      await body(tester);
    } finally {
      FlutterError.onError = original;
    }
  });
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('relativeTime', () {
    final now = DateTime(2026, 11, 2, 12);

    test('dakika, saat ve gün olarak yazar', () {
      expect(relativeTime(now.subtract(const Duration(seconds: 20)), now), 'Az önce');
      expect(relativeTime(now.subtract(const Duration(minutes: 5)), now), '5 dk önce');
      expect(relativeTime(now.subtract(const Duration(hours: 3)), now), '3 saat önce');
      expect(relativeTime(now.subtract(const Duration(days: 2)), now), '2 gün önce');
    });
  });

  group('ihbar listesi', () {
    testApp('örnek ihbar kartı ve filtre sayıları görünür', (tester) async {
      await _pumpHome(tester, FakeReportRepository());
      expect(find.text('Kaldırımda çukur var'), findsOneWidget);
      expect(find.text('Kaldırım'), findsOneWidget); // kategori
      expect(find.text('Çankaya, Ankara'), findsOneWidget);
      expect(find.text('2 gün önce'), findsOneWidget);
      expect(find.text('Henüz ihbarınız yok'), findsNothing);
      // çipler: Tümü 1, Devam eden 1, Onay bekleyen 0, Çözülen 0
      expect(find.widgetWithText(Container, '1'), findsWidgets);
    });

    testApp('durum filtresi kartları süzer', (tester) async {
      await _pumpHome(tester, FakeReportRepository());

      await _tapChip(tester, 'Onay bekleyen');
      expect(find.text('Kaldırımda çukur var'), findsNothing);
      expect(find.text('Bu durumda ihbarınız yok'), findsOneWidget);

      await _tapChip(tester, 'Devam eden');
      expect(find.text('Kaldırımda çukur var'), findsOneWidget);

      await _tapChip(tester, 'Tümü');
      expect(find.text('Kaldırımda çukur var'), findsOneWidget);
    });

    testApp('ihbar yoksa boş durum gösterilir', (tester) async {
      await _pumpHome(tester, FakeReportRepository(reports: const []));
      expect(find.text('Henüz ihbarınız yok'), findsOneWidget);
    });

    testApp('yükleme hatasında Tekrar dene ile liste gelir', (tester) async {
      await _pumpHome(tester, _FailingRepository());
      expect(find.text('İhbarlar yüklenemedi'), findsOneWidget);
      expect(find.text('Kaldırımda çukur var'), findsNothing);

      await tester.tap(find.text('Tekrar dene'));
      await tester.pumpAndSettle();
      expect(find.text('Kaldırımda çukur var'), findsOneWidget);
    });
  });
}
