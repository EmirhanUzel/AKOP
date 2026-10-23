import 'package:dio/dio.dart';

import 'auth_repository.dart';

/// ASP.NET Identity hata kodlarının Türkçesi (sunucu İngilizce döndürüyor).
const _turkish = {
  'PasswordTooShort': 'Parola en az 6 karakter olmalı.',
  'PasswordRequiresNonAlphanumeric': 'Parola en az bir özel karakter içermeli (ör. ! ? .).',
  'PasswordRequiresDigit': 'Parola en az bir rakam içermeli.',
  'PasswordRequiresLower': 'Parola en az bir küçük harf içermeli.',
  'PasswordRequiresUpper': 'Parola en az bir büyük harf içermeli.',
  'InvalidEmail': 'Geçerli bir e-posta girin.',
};

/// IdentityService ile konuşur: POST /api/Auth/login, /api/Auth/register, GET /api/Users/me.
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._dio);

  final Dio _dio;

  @override
  Future<AuthUser> signIn(String email, String password) async {
    final res = await _call(() => _dio.post<dynamic>('/api/Auth/login', data: {'email': email.trim(), 'password': password}));
    if (res.statusCode == 401) throw InvalidCredentials();
    final token = _ok(res)['accessToken'] as String;
    _dio.options.headers['Authorization'] = 'Bearer $token';

    final me = _ok(await _call(() => _dio.get<dynamic>('/api/Users/me')));
    final name = '${me['firstName'] ?? ''} ${me['lastName'] ?? ''}'.trim();
    return AuthUser(fullName: name, email: (me['email'] as String?) ?? email.trim());
  }

  @override
  Future<AuthUser> register(String firstName, String lastName, String email, String password) async {
    final res = await _call(
      () => _dio.post<dynamic>('/api/Auth/register', data: {
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'email': email.trim(),
        'password': password,
      }),
    );
    if (res.statusCode == 400) throw _rejection(res.data);
    _ok(res);
    return signIn(email, password);
  }

  /// Backend'de henüz parola değiştirme uç noktası yok.
  @override
  Future<void> changePassword(String email, String current, String next) =>
      throw UnsupportedError('Parola değiştirme backend\'de henüz yok');

  Future<Response<dynamic>> _call(Future<Response<dynamic>> Function() request) async {
    try {
      return await request();
    } on DioException {
      throw NetworkFailure();
    }
  }

  /// 2xx dışındaki yanıtları (401 ve 400 hariç, çağıran ayrıca ele alır) hataya çevirir.
  Map<String, dynamic> _ok(Response<dynamic> res) {
    final code = res.statusCode ?? 0;
    if (code < 200 || code >= 300) throw NetworkFailure();
    final data = res.data;
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  /// IdentityError listesi ya da ASP.NET doğrulama hatası -> [EmailTaken] / [RegisterRejected].
  Exception _rejection(dynamic data) {
    final messages = <String>[];
    if (data is List) {
      for (final e in data) {
        if (e is Map && e['code'] == 'DuplicateEmail') return EmailTaken();
        if (e is Map && e['description'] is String) messages.add(_turkish[e['code']] ?? e['description'] as String);
      }
    } else if (data is Map && data['errors'] is Map) {
      for (final v in (data['errors'] as Map).values) {
        if (v is List) messages.addAll(v.whereType<String>());
      }
    }
    return RegisterRejected(messages);
  }
}
