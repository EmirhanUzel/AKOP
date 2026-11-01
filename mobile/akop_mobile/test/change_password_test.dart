import 'package:akop_mobile/app.dart';
import 'package:akop_mobile/features/auth/application/auth_controller.dart';
import 'package:akop_mobile/features/auth/data/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Backend'deki gibi: parola değiştirme uç noktası henüz yok.
class _NoEndpointRepository extends FakeAuthRepository {
  _NoEndpointRepository() : super(delay: Duration.zero);

  @override
  Future<void> changePassword(String email, String current, String next) => throw UnsupportedError('yok');
}

Future<void> _pumpApp(WidgetTester tester, AuthRepository repo) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
      child: const AkopApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _login(WidgetTester tester, {String password = '123456'}) async {
  await tester.enterText(find.byType(TextFormField).at(0), 'citizen@akop.test');
  await tester.enterText(find.byType(TextFormField).at(1), password);
  await tester.tap(find.text('Giriş yap'));
  await tester.pumpAndSettle();
}

Future<void> _openChangePassword(WidgetTester tester) async {
  await tester.tap(find.text('Profil'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ListTile, 'Parola değiştir'));
  await tester.pumpAndSettle();
}

Future<void> _fill(WidgetTester tester, String current, String next, String again) async {
  await tester.enterText(find.byType(TextFormField).at(0), current);
  await tester.enterText(find.byType(TextFormField).at(1), next);
  await tester.enterText(find.byType(TextFormField).at(2), again);
  await tester.tap(find.text('Parolayı değiştir'));
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

  testApp('Profil ekranından parola değiştirme ekranı açılır', (tester) async {
    await _pumpApp(tester, FakeAuthRepository(delay: Duration.zero));
    await _login(tester);
    await _openChangePassword(tester);
    expect(find.text('Mevcut parola'), findsOneWidget);
    expect(find.text('Yeni parola'), findsOneWidget);
    expect(find.text('Yeni parola (tekrar)'), findsOneWidget);
  });

  testApp('boş formda alan hataları görünür', (tester) async {
    await _pumpApp(tester, FakeAuthRepository(delay: Duration.zero));
    await _login(tester);
    await _openChangePassword(tester);
    await tester.tap(find.text('Parolayı değiştir'));
    await tester.pumpAndSettle();
    expect(find.text('Mevcut parola zorunludur.'), findsOneWidget);
    expect(find.text('Yeni parola zorunludur.'), findsOneWidget);
  });

  testApp('yeni parola eskisiyle aynıysa ya da tekrarı uyuşmuyorsa hata verir', (tester) async {
    await _pumpApp(tester, FakeAuthRepository(delay: Duration.zero));
    await _login(tester);
    await _openChangePassword(tester);
    await _fill(tester, '123456', '123456', '123456');
    expect(find.text('Yeni parola mevcut parolayla aynı olamaz.'), findsOneWidget);

    await _fill(tester, '123456', 'Yeni123!', 'Baska123!');
    expect(find.text('Parolalar eşleşmiyor.'), findsOneWidget);
  });

  testApp('mevcut parola yanlışsa hata afişi çıkar ve ekranda kalır', (tester) async {
    await _pumpApp(tester, FakeAuthRepository(delay: Duration.zero));
    await _login(tester);
    await _openChangePassword(tester);
    await _fill(tester, 'yanlis', 'Yeni123!', 'Yeni123!');
    expect(find.text('Mevcut parola hatalı.'), findsOneWidget);
    expect(find.text('Parolayı değiştir'), findsOneWidget);
  });

  testApp('başarılı değişiklikte Profil\'e döner ve yeni parolayla giriş yapılır', (tester) async {
    await _pumpApp(tester, FakeAuthRepository(delay: Duration.zero));
    await _login(tester);
    await _openChangePassword(tester);
    await _fill(tester, '123456', 'Yeni123!', 'Yeni123!');
    expect(find.text('Parolanız değiştirildi.'), findsOneWidget);
    expect(find.text('Ayşe Yılmaz'), findsOneWidget);

    await tester.tap(find.text('Çıkış yap'));
    await tester.pumpAndSettle();
    await _login(tester, password: 'Yeni123!');
    expect(find.text('Henüz ihbarınız yok'), findsOneWidget);
  });

  testApp('backend uç noktası yokken bağlı değil mesajı gösterir', (tester) async {
    await _pumpApp(tester, _NoEndpointRepository());
    await _login(tester);
    await _openChangePassword(tester);
    await _fill(tester, '123456', 'Yeni123!', 'Yeni123!');
    expect(find.text('Parola değiştirme henüz sunucuya bağlı değil.'), findsOneWidget);
  });
}
