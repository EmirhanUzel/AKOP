import 'dart:convert';

import 'package:akop_mobile/features/auth/data/auth_repository.dart';
import 'package:akop_mobile/features/reports/data/api_report_repository.dart';
import 'package:akop_mobile/features/reports/data/report_repository.dart';
import 'package:akop_mobile/features/reports/domain/new_report.dart';
import 'package:akop_mobile/features/reports/domain/report.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// İstek URL'lerine göre hazır yanıt döner; hiçbir ağ kullanmaz.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.routes);

  final Map<String, (int, Object?)> routes;
  final calls = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? body, Future<void>? cancel) async {
    calls.add(options);
    await body?.drain<void>(); // multipart dosyası okunup kapanır (Windows silme kilidi)
    final r = routes['${options.method} ${options.uri}'];
    if (r == null) throw DioException.connectionError(requestOptions: options, reason: 'kapalı');
    return ResponseBody.fromString(jsonEncode(r.$2), r.$1, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }

  @override
  void close({bool force = false}) {}
}

(ApiReportRepository, _FakeAdapter) _repo(Map<String, (int, Object?)> routes) {
  final adapter = _FakeAdapter(routes);
  final dio = Dio(BaseOptions(baseUrl: 'http://identity', validateStatus: (s) => s != null && s < 500))..httpClientAdapter = adapter;
  // Telefon eklentisi (JPEG çevirme) testte yok; sahte fotoğraf parçası kullanılır
  Future<MultipartFile> fakePhoto(String _) async => MultipartFile.fromBytes([1, 2, 3], filename: 'photo.jpg');
  return (ApiReportRepository(dio, 'http://report', encode: fakePhoto), adapter);
}

const _created = (201, {'id': 'r1', 'status': 'Pending'});

void main() {
  test('liste: alanları eşler, yeniden eskiye sıralar', () async {
    final (repo, _) = _repo({
      'GET http://report/api/Reports/mine': (200, [
        {'id': 'a', 'title': null, 'description': 'Çukur', 'categoryCode': 'SIDEWALK', 'latitude': 39.9, 'longitude': 32.8, 'locationDescription': null, 'status': 'Pending', 'createdAt': '2026-11-01T10:00:00Z'},
        {'id': 'b', 'title': 'Lamba yanmıyor', 'description': 'x', 'categoryCode': null, 'latitude': 39.9, 'longitude': 32.8, 'locationDescription': 'Okul önü', 'status': 'InProgress', 'createdAt': '2026-11-05T10:00:00Z'},
      ]),
    });
    final list = await repo.myReports();
    expect(list.map((r) => r.id), ['b', 'a']);
    expect(list[0].title, 'Lamba yanmıyor');
    expect(list[0].status, ReportStatus.inProgress);
    expect(list[0].locationText, 'Okul önü');
    expect(list[1].title, 'Kaldırım'); // başlık yoksa kategori adı
    expect(list[1].locationText, '39.90000, 32.80000');
  });

  test('liste: sunucu hatası NetworkFailure olur', () async {
    final (repo, _) = _repo({'GET http://report/api/Reports/mine': (401, null)});
    expect(repo.myReports(), throwsA(isA<NetworkFailure>()));
  });

  test('oluşturma: tek multipart istek, alanlar ve fotoğraflar birlikte, boş alanlar atlanır', () async {
    final (repo, adapter) = _repo({'POST http://report/api/Reports': _created});
    await repo.create(const NewReport(photos: ['a', 'b'], lat: 39.92, lng: 32.85, description: 'd', categoryCode: 'PARK'));
    expect(adapter.calls, hasLength(1)); // ayrı /images isteği yok
    final form = adapter.calls.single.data as FormData;
    expect(Map.fromEntries(form.fields), {'description': 'd', 'categoryCode': 'PARK', 'latitude': '39.92', 'longitude': '32.85'});
    expect(form.files.map((f) => f.key), ['files', 'files']);
  });

  test('oluşturma: 400 gövdesindeki mesaj ReportRejected ile gelir', () async {
    final (repo, _) = _repo({'POST http://report/api/Reports': (400, 'En az bir fotoğraf gerekli.')});
    await expectLater(
      repo.create(const NewReport(photos: ['a'], lat: 1, lng: 2, description: 'd')),
      throwsA(isA<ReportRejected>().having((e) => e.message, 'message', 'En az bir fotoğraf gerekli.')),
    );
  });

  test('oluşturma: 400 ProblemDetails errors haritasından ilk mesajı alır', () async {
    final (repo, _) = _repo({
      'POST http://report/api/Reports': (400, {'errors': {'Files': ['Dosya en fazla 10 MB olabilir.']}}),
    });
    await expectLater(
      repo.create(const NewReport(photos: ['a'], lat: 1, lng: 2, description: 'd')),
      throwsA(isA<ReportRejected>().having((e) => e.message, 'message', 'Dosya en fazla 10 MB olabilir.')),
    );
  });

  test('oluşturma: sunucu 5xx ya da kapalıysa NetworkFailure', () async {
    final (repo, _) = _repo({'POST http://report/api/Reports': (404, null)});
    expect(repo.create(const NewReport(photos: ['a'], lat: 1, lng: 2, description: 'd')), throwsA(isA<NetworkFailure>()));
  });
}
