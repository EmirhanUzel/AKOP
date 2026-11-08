import 'dart:convert';
import 'dart:typed_data';

import 'package:akop_mobile/features/reports/application/report_providers.dart';
import 'package:akop_mobile/features/reports/data/report_repository.dart';
import 'package:akop_mobile/features/reports/domain/new_report.dart';
import 'package:akop_mobile/features/reports/domain/report.dart';
import 'package:akop_mobile/features/reports/presentation/report_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 1x1 PNG.
final _png = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');

class _Photos implements ReportRepository {
  final requested = <String>[];

  @override
  Future<Uint8List> image(String path) async {
    requested.add(path);
    return _png;
  }

  @override
  Future<List<Report>> myReports() async => [];

  @override
  Future<void> create(NewReport report) async {}
}

Future<_Photos> _open(WidgetTester tester, Report report) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final repo = _Photos();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [reportRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(home: ReportDetailScreen(report: report)),
    ),
  );
  await tester.pump();
  await tester.pump();
  return repo;
}

Report _report({List<String> imageUrls = const []}) => Report(
      id: 'a',
      title: 'Kaldırımda çukur var',
      status: ReportStatus.inProgress,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      locationText: 'Okul önü',
      description: 'Taşlar kırık',
      imageUrls: imageUrls,
    );

void main() {
  testWidgets('fotoğraflar indirilir, sayaç gösterilir ve kaydırınca değişir', (tester) async {
    final repo = await _open(tester, _report(imageUrls: ['/api/Reports/a/images/1', '/api/Reports/a/images/2']));
    expect(find.text('Kaldırımda çukur var'), findsOneWidget);
    expect(find.text('Taşlar kırık'), findsOneWidget);
    expect(find.text('Okul önü'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(repo.requested, ['/api/Reports/a/images/1']); // yalnız görünen sayfa istenir
    expect(find.text('1 / 2'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);
    expect(repo.requested, contains('/api/Reports/a/images/2'));
  });

  testWidgets('fotoğrafsız ihbarda fotoğraf alanı ve sayaç yok', (tester) async {
    final repo = await _open(tester, _report());
    expect(find.byType(PageView), findsNothing);
    expect(repo.requested, isEmpty);
  });
}
