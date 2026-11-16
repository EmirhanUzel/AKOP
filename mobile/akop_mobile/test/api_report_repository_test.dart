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

const _categories = {
  'GET http://report/api/Reports/categories': (200, [
    {'code': 'SIDEWALK', 'name': 'Kaldırım', 'subcategories': [{'code': 'CURB_DAMAGE', 'name': 'Bordür hasarı'}]},
    {'code': 'OTHER', 'name': 'Diğer', 'subcategories': []},
  ]),
};

const _suggestUrl = 'POST http://report/api/Reports/category-suggestions';

void main() {
  test('liste: alanları eşler, yeniden eskiye sıralar', () async {
    final (repo, _) = _repo({
      'GET http://report/api/Reports/mine': (200, [
        {'id': 'a', 'title': null, 'description': 'Çukur', 'categoryCode': 'SIDEWALK', 'latitude': 39.9, 'longitude': 32.8, 'locationDescription': null, 'status': 'Pending', 'createdAt': '2026-11-01T10:00:00Z'},
        {'id': 'b', 'title': 'Lamba yanmıyor', 'description': 'x', 'categoryCode': null, 'latitude': 39.9, 'longitude': 32.8, 'locationDescription': 'Okul önü', 'status': 'InProgress', 'createdAt': '2026-11-05T10:00:00Z'},
      ]),
      ..._categories,
    });
    final list = await repo.myReports();
    expect(list.map((r) => r.id), ['b', 'a']);
    expect(list[0].title, 'Lamba yanmıyor');
    expect(list[0].status, ReportStatus.inProgress);
    expect(list[0].locationText, 'Okul önü');
    expect(list[1].title, 'Kaldırım'); // başlık yoksa kategori adı
    expect(list[1].locationText, '39.90000, 32.80000');
  });

  test('liste: açıklama ve fotoğraf adreslerini alır', () async {
    final (repo, _) = _repo({
      'GET http://report/api/Reports/mine': (200, [
        {'id': 'a', 'title': 'T', 'description': 'Çukur var', 'categoryCode': null, 'latitude': 39.9, 'longitude': 32.8, 'locationDescription': null, 'status': 'Pending', 'createdAt': '2026-11-01T10:00:00Z', 'imageUrls': ['/api/Reports/a/images/1', '/api/Reports/a/images/2']},
        {'id': 'b', 'title': 'T', 'description': 'x', 'categoryCode': null, 'latitude': 39.9, 'longitude': 32.8, 'locationDescription': null, 'status': 'Pending', 'createdAt': '2026-11-02T10:00:00Z'},
      ]),
    });
    final list = await repo.myReports();
    expect(list.last.description, 'Çukur var');
    expect(list.last.imageUrls, ['/api/Reports/a/images/1', '/api/Reports/a/images/2']);
    expect(list.first.imageUrls, isEmpty); // imageUrls gelmezse boş liste
  });

  test('fotoğraf: göreli adresi ReportService adresiyle birleştirip bayt olarak ister', () async {
    final (repo, adapter) = _repo({'GET http://report/api/Reports/a/images/1': (200, 'resim')});
    final bytes = await repo.image('/api/Reports/a/images/1');
    expect(bytes, isNotEmpty);
    expect(adapter.calls.single.responseType, ResponseType.bytes);
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

  test('oluşturma: alt kategori gönderilir', () async {
    final (repo, adapter) = _repo({'POST http://report/api/Reports': _created});
    await repo.create(const NewReport(photos: ['a'], lat: 1, lng: 2, description: 'd', categoryCode: 'SIDEWALK', subcategoryCode: 'CURB_DAMAGE'));
    final form = adapter.calls.single.data as FormData;
    expect(Map.fromEntries(form.fields)['subcategoryCode'], 'CURB_DAMAGE');
  });

  test('kategoriler: alt kategorileriyle eşlenir, ikinci çağrıda istek atılmaz', () async {
    final (repo, adapter) = _repo(_categories);
    final list = await repo.categories();
    expect(list.map((c) => c.code), ['SIDEWALK', 'OTHER']);
    expect(list.first.subcategories.single.name, 'Bordür hasarı');
    await repo.categories();
    expect(adapter.calls, hasLength(1));
  });

  test('liste: kategoriler gelmezse başlıksız ihbar yine listelenir', () async {
    final (repo, _) = _repo({
      'GET http://report/api/Reports/mine': (200, [
        {'id': 'a', 'title': null, 'description': 'Çukur', 'categoryCode': 'SIDEWALK', 'latitude': 39.9, 'longitude': 32.8, 'status': 'Pending', 'createdAt': '2026-11-01T10:00:00Z'},
      ]),
    });
    expect((await repo.myReports()).single.title, 'Çukur');
  });

  test('öneri: File alanında tek fotoğraf, yanıt eşlenir', () async {
    final (repo, adapter) = _repo({
      _suggestUrl: (200, {
        'suggestions': [
          {'code': 'ROAD_DAMAGE', 'name': 'Yol hasarı', 'confidence': 0.845},
          {'code': 'SIDEWALK', 'name': 'Kaldırım', 'confidence': 0.1484},
          {'code': 'WATER_LEAK', 'name': 'Su ve kanalizasyon', 'confidence': 0.004},
        ],
        'isConfident': true,
        'selectedCategory': null,
      }),
    });
    final s = await repo.suggestCategory('a');
    final form = adapter.calls.single.data as FormData;
    expect(form.files.map((f) => f.key), ['File']);
    expect(form.fields, isEmpty);
    expect(s.isConfident, isTrue);
    expect(s.suggestions.map((g) => g.code), ['ROAD_DAMAGE', 'SIDEWALK', 'WATER_LEAK']);
    expect(s.suggestions.first.confidence, 0.845);
    expect(s.matchesImage, isNull);
  });

  test('öneri: CategoryCode gönderilince matchesImage gelir', () async {
    final (repo, adapter) = _repo({
      _suggestUrl: (200, {
        'suggestions': [],
        'isConfident': false,
        'selectedCategory': {'code': 'LIGHTING', 'confidence': 0, 'matchesImage': false},
      }),
    });
    final s = await repo.suggestCategory('a', categoryCode: 'LIGHTING');
    expect(Map.fromEntries((adapter.calls.single.data as FormData).fields), {'CategoryCode': 'LIGHTING'});
    expect(s.matchesImage, isFalse);
  });

  test('öneri: model yoksa (503) NetworkFailure', () async {
    final (repo, _) = _repo({_suggestUrl: (503, null)});
    expect(repo.suggestCategory('a'), throwsA(isA<NetworkFailure>()));
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
