import 'package:akop_mobile/app.dart';
import 'package:akop_mobile/features/auth/application/auth_controller.dart';
import 'package:akop_mobile/features/auth/data/auth_repository.dart';
import 'package:akop_mobile/features/reports/application/reports_controller.dart';
import 'package:akop_mobile/features/reports/data/report_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

Future<void> pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository(delay: Duration.zero)),
        reportRepositoryProvider.overrideWithValue(FakeReportRepository(delay: Duration.zero)),
      ],
      child: const AkopApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> login(WidgetTester tester) async {
  await tester.enterText(find.byType(TextFormField).at(0), 'citizen@akop.test');
  await tester.enterText(find.byType(TextFormField).at(1), '123456');
  await tester.tap(find.text('Giriş yap'));
  await tester.pumpAndSettle();
}
