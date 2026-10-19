import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testApp('detay açılır ve zaman çizelgesi görünür', (tester) async {
    await pumpApp(tester);
    await login(tester);
    await tester.tap(find.text('Sokağın ortasında derin çukur'));
    await tester.pumpAndSettle();
    expect(find.text('İhbar Detayı'), findsOneWidget);
    expect(find.text('Saha ekibi sorun üzerinde çalışıyor.'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Çözüm doğrulaması'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('Bekleniyor'), findsOneWidget);
  });

  testApp('çözümü doğrulayınca ihbar çözüldü olur', (tester) async {
    await pumpApp(tester);
    await login(tester);
    await tester.tap(find.text('Doğrula'));
    await tester.pumpAndSettle();
    expect(find.text('Çözümü Doğrula'), findsOneWidget);

    final send = find.widgetWithText(FilledButton, 'Doğrulamayı Gönder');
    expect(tester.widget<FilledButton>(send).onPressed, isNull);

    await tester.scrollUntilVisible(find.text('Çözüldü'), 200);
    await tester.tap(find.text('Çözüldü'));
    await tester.pump();
    await tester.tap(send);
    await tester.pumpAndSettle();

    expect(find.text('Onayınız bekleniyor'), findsNothing);
    expect(find.text('Teşekkürler, ihbarınız kapatıldı.'), findsOneWidget);
  });

  testApp('ek bilgi gerekli ihbar için açıklama yazmadan gönderilemez', (tester) async {
    await pumpApp(tester);
    await login(tester);
    final list = find.descendant(of: find.byType(RefreshIndicator), matching: find.byType(Scrollable)).first;
    await tester.scrollUntilVisible(find.text('Su borusu patlak'), 200, scrollable: list);
    await tester.tap(find.text('Su borusu patlak'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ek bilgi ver'));
    await tester.pumpAndSettle();

    final send = find.widgetWithText(FilledButton, 'Gönder');
    expect(tester.widget<FilledButton>(send).onPressed, isNull);
    await tester.enterText(find.byType(TextField).first, 'Boru kaldırımın köşesinde.');
    await tester.pump();
    expect(tester.widget<FilledButton>(send).onPressed, isNotNull);
  });
}
