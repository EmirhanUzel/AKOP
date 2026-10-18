import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:akop_mobile/main.dart';

void main() {
  testWidgets('AKOP başlangıç ekranı testi', (WidgetTester tester) async {
    await tester.pumpWidget(const AKOPApp());

    expect(find.text('AKOP'), findsOneWidget);
    expect(find.text('AKOP Mobil Uygulaması'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}