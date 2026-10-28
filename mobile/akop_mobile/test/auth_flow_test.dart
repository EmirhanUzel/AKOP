import 'package:akop_mobile/app.dart';
import 'package:akop_mobile/features/auth/application/auth_controller.dart';
import 'package:akop_mobile/features/auth/data/auth_repository.dart';
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
      ],
      child: const AkopApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _login(WidgetTester tester) async {
  await tester.enterText(find.byType(TextFormField).at(0), 'citizen@akop.test');
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

  group('giriş', () {
    testApp('boş gönderimde alan hataları görünür', (tester) async {
      await _pumpApp(tester);
      await tester.tap(find.text('Giriş yap'));
      await tester.pump();
      expect(find.text('E-posta zorunludur.'), findsOneWidget);
      expect(find.text('Parola zorunludur.'), findsOneWidget);
    });

    testApp('yanlış parolada hata afişi çıkar', (tester) async {
      await _pumpApp(tester);
      await tester.enterText(find.byType(TextFormField).at(0), 'citizen@akop.test');
      await tester.enterText(find.byType(TextFormField).at(1), 'yanlis');
      await tester.tap(find.text('Giriş yap'));
      await tester.pumpAndSettle();
      expect(find.text('E-posta veya parola hatalı.'), findsOneWidget);
    });

    testApp('doğru hesapla ihbar listesine geçer, çıkışta girişe döner', (tester) async {
      await _pumpApp(tester);
      await _login(tester);
      expect(find.text('Henüz ihbarınız yok'), findsOneWidget);
      await tester.tap(find.byTooltip('Çıkış yap'));
      await tester.pumpAndSettle();
      expect(find.text('Hoş geldiniz'), findsOneWidget);
    });
  });

  group('ana ekran', () {
    testApp('Profil sekmesi yönlendirmez, İhbar Et akışı açar', (tester) async {
      await _pumpApp(tester);
      await _login(tester);
      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();
      expect(find.text('Henüz ihbarınız yok'), findsOneWidget);
      await tester.tap(find.byTooltip('İhbar Et'));
      await tester.pumpAndSettle();
      expect(find.text('Sorunu fotoğraflayın'), findsOneWidget);
    });
  });

  group('kayıt', () {
    Future<void> openRegister(WidgetTester tester) async {
      await _pumpApp(tester);
      await tester.tap(find.text('Hesap oluştur'));
      await tester.pumpAndSettle();
    }

    Future<void> fill(WidgetTester tester, {required String email, String again = 'sifre1'}) async {
      await tester.enterText(find.byType(TextFormField).at(0), 'Ali');
      await tester.enterText(find.byType(TextFormField).at(1), 'Veli');
      await tester.enterText(find.byType(TextFormField).at(2), email);
      await tester.enterText(find.byType(TextFormField).at(3), 'sifre1');
      await tester.enterText(find.byType(TextFormField).at(4), again);
      final submit = find.widgetWithText(FilledButton, 'Hesap oluştur');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
    }

    testApp('parolalar eşleşmezse hata verir', (tester) async {
      await openRegister(tester);
      await fill(tester, email: 'yeni@akop.test', again: 'baska');
      expect(find.text('Parolalar eşleşmiyor.'), findsOneWidget);
    });

    testApp('kayıtlı e-posta hata verir, yeni e-posta giriş yapar', (tester) async {
      await openRegister(tester);
      await fill(tester, email: 'citizen@akop.test');
      expect(find.text('Bu e-posta ile kayıtlı bir hesap var.'), findsOneWidget);
      await fill(tester, email: 'yeni@akop.test');
      expect(find.text('Henüz ihbarınız yok'), findsOneWidget);
    });
  });
}
