import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testApp('liste 5 ihbarı ve durum rozetlerini gösterir', (tester) async {
    await pumpApp(tester);
    await login(tester);
    expect(find.text('Sokağın ortasında derin çukur'), findsOneWidget);
    expect(find.text('Çalışma sürüyor'), findsOneWidget);
    expect(find.text('Onayınız bekleniyor'), findsOneWidget);
  });

  testApp('filtre yalnız eşleşenleri gösterir', (tester) async {
    await pumpApp(tester);
    await login(tester);
    await tester.tap(find.textContaining('Onay bekleyen'));
    await tester.pumpAndSettle();
    expect(find.text('Sokak lambası yanmıyor'), findsOneWidget);
    expect(find.text('Su borusu patlak'), findsNothing);
  });

  testApp('profil adı gösterir ve parola ekranı açılır', (tester) async {
    await pumpApp(tester);
    await login(tester);
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Ayşe Yılmaz'), findsOneWidget);
    await tester.tap(find.text('Parolayı değiştir'));
    await tester.pumpAndSettle();
    expect(find.text('Mevcut parola'), findsOneWidget);
  });
}
