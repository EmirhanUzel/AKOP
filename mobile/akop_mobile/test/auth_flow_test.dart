import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('giriş', () {
    testApp('boş gönderimde alan hataları görünür', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Giriş yap'));
      await tester.pump();
      expect(find.text('E-posta zorunludur.'), findsOneWidget);
      expect(find.text('Parola zorunludur.'), findsOneWidget);
    });

    testApp('yanlış parolada hata afişi çıkar', (tester) async {
      await pumpApp(tester);
      await tester.enterText(find.byType(TextFormField).at(0), 'citizen@akop.test');
      await tester.enterText(find.byType(TextFormField).at(1), 'yanlis');
      await tester.tap(find.text('Giriş yap'));
      await tester.pumpAndSettle();
      expect(find.text('E-posta veya parola hatalı.'), findsOneWidget);
    });

    testApp('doğru hesapla ihbar listesi açılır, profilden çıkış girişe döner', (tester) async {
      await pumpApp(tester);
      await login(tester);
      expect(find.text('Sokağın ortasında derin çukur'), findsOneWidget);
      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Çıkış yap'));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Çıkış yap')));
      await tester.pumpAndSettle();
      expect(find.text('Hoş geldiniz'), findsOneWidget);
    });
  });

  group('kayıt', () {
    Future<void> openRegister(WidgetTester tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Hesap oluştur'));
      await tester.pumpAndSettle();
    }

    Future<void> fill(WidgetTester tester, {required String email, String again = 'sifre1'}) async {
      await tester.enterText(find.byType(TextFormField).at(0), 'Ali Veli');
      await tester.enterText(find.byType(TextFormField).at(1), email);
      await tester.enterText(find.byType(TextFormField).at(2), 'sifre1');
      await tester.enterText(find.byType(TextFormField).at(3), again);
      await tester.tap(find.widgetWithText(FilledButton, 'Hesap oluştur'));
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
      expect(find.text('Sokağın ortasında derin çukur'), findsOneWidget);
    });
  });
}
