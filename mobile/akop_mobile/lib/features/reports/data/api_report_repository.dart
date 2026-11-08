import 'package:dio/dio.dart';

import '../../auth/data/auth_repository.dart';
import '../domain/new_report.dart';
import '../domain/report.dart';
import '../domain/report_category.dart';
import 'report_repository.dart';

/// ReportService ile konuşur: GET /api/Reports/mine, POST /api/Reports ve
/// POST /api/Reports/{id}/images (multipart, her fotoğraf `files` alanında).
/// Token ve 401 yenilemesi paylaşılan Dio'daki auth interceptor'ından gelir.
class ApiReportRepository implements ReportRepository {
  ApiReportRepository(this._dio, this._baseUrl);

  final Dio _dio;
  final String _baseUrl;

  @override
  Future<List<Report>> myReports() async {
    final data = _ok(await _call(() => _dio.get<dynamic>('$_baseUrl/api/Reports/mine')));
    final list = data is List ? data.whereType<Map<String, dynamic>>().map(_report).toList() : <Report>[];
    return list..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<void> create(NewReport r) async {
    final created = _ok(await _call(() => _dio.post<dynamic>('$_baseUrl/api/Reports', data: {
          'title': r.title,
          'description': r.description,
          'categoryCode': r.categoryCode,
          'latitude': r.lat,
          'longitude': r.lng,
          'locationDescription': r.locationDescription,
        })));
    if (r.photos.isEmpty) return;
    try {
      final form = FormData.fromMap({'files': [for (final p in r.photos) await MultipartFile.fromFile(p)]});
      _ok(await _call(() => _dio.post<dynamic>('$_baseUrl/api/Reports/${(created as Map)['id']}/images', data: form)));
    } on Exception {
      throw PhotoUploadFailed();
    }
  }

  Report _report(Map<String, dynamic> j) {
    final title = j['title'] as String?;
    final code = j['categoryCode'] as String?;
    final place = j['locationDescription'] as String?;
    final status = (j['status'] as String? ?? '').toLowerCase();
    return Report(
      id: j['id'].toString(),
      title: title ?? categoryOf(code)?.name ?? j['description'] as String? ?? '',
      status: ReportStatus.values.firstWhere((s) => s.name.toLowerCase() == status, orElse: () => ReportStatus.pending),
      createdAt: DateTime.parse(j['createdAt'] as String).toLocal(),
      locationText: place ?? '${(j['latitude'] as num).toStringAsFixed(5)}, ${(j['longitude'] as num).toStringAsFixed(5)}',
      categoryCode: code,
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
}
