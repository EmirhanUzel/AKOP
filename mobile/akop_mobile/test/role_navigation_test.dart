import 'package:akop_mobile/app.dart';
import 'package:akop_mobile/features/auth/application/auth_controller.dart';
import 'package:akop_mobile/features/auth/data/auth_repository.dart';
import 'package:akop_mobile/features/reports/application/report_providers.dart';
import 'package:akop_mobile/features/reports/data/report_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository(delay: Duration.zero)),
        reportRepositoryProvider.overrideWithValue(FakeReportRepository(reports: const [])),
      ],
      child: const AkopApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _login(WidgetTester tester, String email) async {
  await tester.enterText(find.byType(TextFormField).at(0), email);
  await tester.enterText(find.byType(TextFormField).at(1), '123456');
  await tester.tap(find.text('Giriş yap'));
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

  group('rol çözümleme', () {
    test('API rol adları UserRole değerine çevrilir', () {
      expect(UserRole.parse('Citizen'), UserRole.citizen);
      expect(UserRole.parse('FieldStaff'), UserRole.fieldStaff);
      expect(UserRole.parse('OrgManager'), UserRole.other);
      expect(UserRole.parse('SystemAdmin'), UserRole.other);
      expect(UserRole.parse(null), UserRole.other);
    });

    test('yalnızca vatandaş ve saha personeli mobil uygulamayı kullanır', () {
      expect(UserRole.citizen.usesMobileApp, isTrue);
      expect(UserRole.fieldStaff.usesMobileApp, isTrue);
      expect(UserRole.other.usesMobileApp, isFalse);
    });
  });

  group('vatandaş', () {
    testApp('ihbar listesi, İhbar Et butonu ve Profil sekmesi görünür', (tester) async {
      await _pumpApp(tester);
      await _login(tester, 'citizen@akop.test');
      expect(find.text('Henüz ihbarınız yok'), findsOneWidget);
      expect(find.byTooltip('İhbar Et'), findsOneWidget);
      expect(find.text('Görevler'), findsNothing);
    });

    testApp('İhbar Et ihbar akışını açar', (tester) async {
      await _pumpApp(tester);
      await _login(tester, 'citizen@akop.test');
      await tester.tap(find.byTooltip('İhbar Et'));
      await tester.pumpAndSettle();
      expect(find.text('Sorunu fotoğraflayın'), findsOneWidget);
    });

    testApp('Profil sekmesi adı, e-postayı ve rolü gösterir; İhbarlarım\'a geri döner', (tester) async {
      await _pumpApp(tester);
      await _login(tester, 'citizen@akop.test');
      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();
      expect(find.text('Ayşe Yılmaz'), findsOneWidget);
      expect(find.text('citizen@akop.test'), findsOneWidget);
      expect(find.text('Vatandaş'), findsOneWidget);
      expect(find.text('Henüz ihbarınız yok'), findsNothing);

      await tester.tap(find.text('İhbarlarım'));
      await tester.pumpAndSettle();
      expect(find.text('Henüz ihbarınız yok'), findsOneWidget);
    });
  });

  group('saha personeli', () {
    testApp('görevler ekranı açılır, İhbar Et butonu yoktur', (tester) async {
      await _pumpApp(tester);
      await _login(tester, 'fieldstaff@akop.test');
      expect(find.text('Henüz görev atanmadı'), findsOneWidget);
      expect(find.byTooltip('İhbar Et'), findsNothing);
      expect(find.text('Henüz ihbarınız yok'), findsNothing);
    });

    testApp('Profil sekmesi rolü gösterir ve çıkış girişe döner', (tester) async {
      await _pumpApp(tester);
      await _login(tester, 'fieldstaff@akop.test');
      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();
      expect(find.text('Mehmet Demir'), findsOneWidget);
      expect(find.text('Saha personeli'), findsOneWidget);

      await tester.tap(find.text('Çıkış yap'));
      await tester.pumpAndSettle();
      expect(find.text('Hoş geldiniz'), findsOneWidget);
    });
  });

  group('web paneli rolleri', () {
    testApp('kurum yöneticisi mobil uygulamaya alınmaz', (tester) async {
      await _pumpApp(tester);
      await _login(tester, 'manager@akop.test');
      expect(find.textContaining('mobil uygulamada kullanılamıyor'), findsOneWidget);
      expect(find.text('Hoş geldiniz'), findsOneWidget);
      expect(find.text('Henüz ihbarınız yok'), findsNothing);
    });
  });
}
