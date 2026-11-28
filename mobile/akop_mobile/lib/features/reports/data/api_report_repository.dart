import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../../auth/data/auth_repository.dart';
import '../domain/new_report.dart';
import '../domain/report.dart';
import '../domain/report_category.dart';
import 'report_repository.dart';

/// Fotoğrafı yükleme biçimine çevirir; testlerde telefon eklentisi olmadan değiştirilir.
typedef PhotoEncoder = Future<MultipartFile> Function(String path);

/// Sunucu HEIC/HEIF kabul etmez: fotoğraf JPEG'e çevrilir, uzun kenar 1920 px'e, kalite %80'e indirilir.
Future<MultipartFile> jpegPart(String path) async {
  final bytes = await FlutterImageCompress.compressWithFile(path, minWidth: 1920, minHeight: 1920, quality: 80);
  if (bytes == null) throw ReportRejected('Fotoğraf işlenemedi. Başka bir fotoğraf deneyin.');
  return MultipartFile.fromBytes(bytes, filename: 'photo.jpg', contentType: DioMediaType('image', 'jpeg'));
}

/// ReportService ile konuşur: GET /api/Reports/mine, GET /api/Reports/categories,
/// POST /api/Reports/category-suggestions ve POST /api/Reports
/// (multipart/form-data: metin alanları + `files` alanında 1-5 fotoğraf, tek istekte).
/// Token ve 401 yenilemesi paylaşılan Dio'daki auth interceptor'ından gelir.
class ApiReportRepository implements ReportRepository {
  ApiReportRepository(this._dio, this._baseUrl, {this._encode = jpegPart});

  final Dio _dio;
  final String _baseUrl;
  final PhotoEncoder _encode;
  List<ReportCategory>? _categories;

  @override
  Future<List<Report>> myReports() async {
    final data = _ok(await _call(() => _dio.get<dynamic>('$_baseUrl/api/Reports/mine')));
    // Kategori adı yalnızca başlıksız ihbarlarda başlık olur; gelmezse liste yine açılır
    final categories = await this.categories().then<List<ReportCategory>?>((c) => c, onError: (_) => null);
    final list = data is List ? data.whereType<Map<String, dynamic>>().map((j) => _report(j, categories)).toList() : <Report>[];
    return list..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<void> create(NewReport r) async {
    final form = FormData.fromMap({
      if (r.title != null) 'title': r.title,
      'description': r.description,
      if (r.categoryCode != null) 'categoryCode': r.categoryCode,
      if (r.subcategoryCode != null) 'subcategoryCode': r.subcategoryCode,
      'latitude': r.lat, // Dart double'ı nokta ile yazar (39.92), sunucu bunu bekler
      'longitude': r.lng,
      if (r.locationDescription != null) 'locationDescription': r.locationDescription,
      if (r.answers.isNotEmpty) 'answers': jsonEncode(r.answers), // {"SIZE":"LARGE"}
      'files': [for (final p in r.photos) await _encode(p)],
    });
    final res = await _call(() => _dio.post<dynamic>('$_baseUrl/api/Reports', data: form));
    if (res.statusCode == 400) throw ReportRejected(_message(res.data));
    _ok(res);
  }

  /// Fotoğraf `Authorization` ister: istek paylaşılan Dio'dan geçtiği için token oradan eklenir.
  @override
  Future<Uint8List> image(String path) async {
    final res = await _call(() => _dio.get<List<int>>('$_baseUrl$path', options: Options(responseType: ResponseType.bytes)));
    return Uint8List.fromList((_ok(res) as List).cast<int>());
  }

  /// Liste oturum boyunca değişmez; ilk başarılı yanıt saklanır.
  @override
  Future<List<ReportCategory>> categories() async {
    if (_categories case final c?) return c;
    final data = _ok(await _call(() => _dio.get<dynamic>('$_baseUrl/api/Reports/categories')));
    if (data is! List) throw NetworkFailure();
    return _categories = [
      for (final c in data.whereType<Map<String, dynamic>>())
        ReportCategory(c['code'] as String, c['name'] as String, [
          for (final s in (c['subcategories'] as List? ?? const []).whereType<Map<String, dynamic>>())
            ReportSubcategory(s['code'] as String, s['name'] as String),
        ], [
          for (final q in (c['questions'] as List? ?? const []).whereType<Map<String, dynamic>>())
            ReportQuestion(q['code'] as String, q['text'] as String, [
              for (final o in (q['options'] as List? ?? const []).whereType<Map<String, dynamic>>())
                ReportQuestionOption(o['code'] as String, o['text'] as String),
            ]),
        ]),
    ];
  }

  /// 503 (model yok) dahil her hata NetworkFailure olur; çağıran öneriyi göstermeden devam eder.
  @override
  Future<CategorySuggestion> suggestCategory(String photo, {String? categoryCode}) async {
    final form = FormData.fromMap({
      'File': await _encode(photo),
      'CategoryCode': ?categoryCode,
    });
    final data = _ok(await _call(() => _dio.post<dynamic>('$_baseUrl/api/Reports/category-suggestions', data: form)));
    if (data is! Map) throw NetworkFailure();
    final selected = data['selectedCategory'];
    return CategorySuggestion(
      suggestions: [
        for (final g in (data['suggestions'] as List? ?? const []).whereType<Map<String, dynamic>>())
          CategoryGuess(g['code'] as String, g['name'] as String, (g['confidence'] as num).toDouble()),
      ],
      isConfident: data['isConfident'] == true,
      matchesImage: selected is Map ? selected['matchesImage'] as bool? : null,
    );
  }

  Report _report(Map<String, dynamic> j, List<ReportCategory>? categories) {
    final title = j['title'] as String?;
    final code = j['categoryCode'] as String?;
    final place = j['locationDescription'] as String?;
    final status = (j['status'] as String? ?? '').toLowerCase();
    return Report(
      id: j['id'].toString(),
      title: title ?? categoryOf(categories, code)?.name ?? j['description'] as String? ?? '',
      status: ReportStatus.values.firstWhere((s) => s.name.toLowerCase() == status, orElse: () => ReportStatus.pending),
      createdAt: DateTime.parse(j['createdAt'] as String).toLocal(),
      locationText: place ?? '${(j['latitude'] as num).toStringAsFixed(5)}, ${(j['longitude'] as num).toStringAsFixed(5)}',
      categoryCode: code,
      subcategoryCode: j['subcategoryCode'] as String?,
      description: j['description'] as String? ?? '',
      imageUrls: [...?(j['imageUrls'] as List?)?.whereType<String>()],
      answers: {
        for (final e in (j['answers'] as Map? ?? const {}).entries)
          if (e.key is String && e.value is String) e.key as String: e.value as String,
      },
    );
  }

  Future<Response<dynamic>> _call(Future<Response<dynamic>> Function() request) async {
    try {
      return await request();
    } on DioException {
      throw NetworkFailure();
    }
  }

  dynamic _ok(Response<dynamic> res) {
    final code = res.statusCode ?? 0;
    if (code < 200 || code >= 300) throw NetworkFailure();
    return res.data;
  }

  /// Sunucunun 400 gövdesinden (düz metin, ProblemDetails ya da hata listesi) kullanıcıya gösterilecek cümle.
  String _message(dynamic data) {
    if (data is String && data.trim().isNotEmpty) return data.trim();
    if (data is Map) {
      final errors = data['errors'];
      if (errors is Map) {
        for (final v in errors.values) {
          if (v is List && v.isNotEmpty && v.first is String) return v.first as String;
        }
      }
      if (data['detail'] is String) return data['detail'] as String;
    }
    if (data is List && data.isNotEmpty && data.first is Map && (data.first as Map)['description'] is String) {
      return data.map((e) => (e as Map)['description']).join(' ');
    }
    return 'İhbar gönderilemedi. Bilgileri kontrol edin.';
  }
}
