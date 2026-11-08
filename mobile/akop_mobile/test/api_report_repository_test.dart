import 'dart:convert';
import 'dart:io';

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
  return (ApiReportRepository(dio, 'http://report'), adapter);
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

  test('oluşturma: DTO alanlarını gönderir, fotoğraf yoksa yükleme yapmaz', () async {
    final (repo, adapter) = _repo({'POST http://report/api/Reports': _created});
    await repo.create(const NewReport(photos: [], lat: 1, lng: 2, description: 'd', categoryCode: 'PARK', locationDescription: 'yer'));
    expect(adapter.calls, hasLength(1));
    expect(adapter.calls.single.data, {'title': null, 'description': 'd', 'categoryCode': 'PARK', 'latitude': 1.0, 'longitude': 2.0, 'locationDescription': 'yer'});
  });

  test('oluşturma: fotoğrafları yeni ihbarın images ucuna yükler', () async {
    final dir = await Directory.systemTemp.createTemp('akop');
    addTearDown(() => dir.delete(recursive: true));
    final photo = File('${dir.path}/a.jpg')..writeAsBytesSync([1, 2, 3]);
    final (repo, adapter) = _repo({'POST http://report/api/Reports': _created, 'POST http://report/api/Reports/r1/images': (200, null)});
    await repo.create(NewReport(photos: [photo.path], lat: 1, lng: 2, description: 'd'));
    final upload = adapter.calls.last.data as FormData;
    expect(upload.files.single.key, 'files');
  });

  test('oluşturma: ihbar açılır ama yükleme düşerse PhotoUploadFailed', () async {
    final dir = await Directory.systemTemp.createTemp('akop');
    addTearDown(() => dir.delete(recursive: true));
    final photo = File('${dir.path}/a.jpg')..writeAsBytesSync([1]);
    final (repo, _) = _repo({'POST http://report/api/Reports': _created, 'POST http://report/api/Reports/r1/images': (404, null)});
    expect(repo.create(NewReport(photos: [photo.path], lat: 1, lng: 2, description: 'd')), throwsA(isA<PhotoUploadFailed>()));
  });

  test('oluşturma: ihbar açılamazsa NetworkFailure (PhotoUploadFailed değil)', () async {
    final (repo, _) = _repo({'POST http://report/api/Reports': (400, null)});
    expect(repo.create(const NewReport(photos: ['x'], lat: 1, lng: 2, description: 'd')), throwsA(isA<NetworkFailure>()));
  });
}
