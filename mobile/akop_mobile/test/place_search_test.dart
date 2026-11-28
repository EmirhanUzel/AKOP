import 'dart:convert';

import 'package:akop_mobile/features/reports/data/place_search.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAdapter implements HttpClientAdapter {
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? body, Future<void>? cancel) async {
    last = options;
    return ResponseBody.fromString(
      jsonEncode([
        {'display_name': 'Kızılay, Çankaya, Ankara', 'lat': '39.9208', 'lon': '32.8541'},
        {'display_name': 'Bozuk', 'lat': 'x', 'lon': '32.8'},
      ]),
      200,
      headers: {Headers.contentTypeHeader: ['application/json']},
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('arama: Türkiye ile sınırlı ister, koordinatı bozuk sonucu atlar', () async {
    final adapter = _FakeAdapter();
    final places = await PlaceSearch(Dio()..httpClientAdapter = adapter).search('Kızılay');
    expect(adapter.last!.queryParameters['countrycodes'], 'tr');
    expect(adapter.last!.headers['Authorization'], isNull);
    expect(places.single.name, 'Kızılay, Çankaya, Ankara');
    expect(places.single.point.latitude, 39.9208);
  });
}
