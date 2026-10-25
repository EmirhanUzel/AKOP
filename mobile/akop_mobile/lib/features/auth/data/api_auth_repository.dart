import 'package:dio/dio.dart';

import 'auth_repository.dart';
import 'token_store.dart';

/// ASP.NET Identity hata kodlarının Türkçesi (sunucu İngilizce döndürüyor).
const _turkish = {
  'PasswordTooShort': 'Parola en az 6 karakter olmalı.',
  'PasswordRequiresNonAlphanumeric': 'Parola en az bir özel karakter içermeli (ör. ! ? .).',
  'PasswordRequiresDigit': 'Parola en az bir rakam içermeli.',
  'PasswordRequiresLower': 'Parola en az bir küçük harf içermeli.',
  'PasswordRequiresUpper': 'Parola en az bir büyük harf içermeli.',
  'InvalidEmail': 'Geçerli bir e-posta girin.',
};

/// IdentityService ile konuşur: /api/Auth/login, register, refresh, logout ve GET /api/Users/me.
/// Access token bellekte, refresh token [TokenStore]'da tutulur; access token süresi dolunca
/// (401) bir kez yenilenip istek tekrarlanır.
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._dio, this._store) {
    _dio.interceptors.add(InterceptorsWrapper(onRequest: _attachToken, onResponse: _retryOn401));
  }

  final Dio _dio;
  final TokenStore _store;
  String? _access;
  Future<bool>? _refreshing;

  @override
  void Function()? onSessionExpired;

  @override
  Future<AuthUser> signIn(String email, String password) async {
    final res = await _call(() => _dio.post<dynamic>('/api/Auth/login', data: {'email': email.trim(), 'password': password}));
    if (res.statusCode == 401) throw InvalidCredentials();
    await _storeTokens(_ok(res));
    return _me(fallbackEmail: email.trim());
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

  @override
  Future<AuthUser?> restoreSession() async {
    try {
      if (!await _refresh()) return null;
      return await _me();
    } on NetworkFailure {
      return null; // token silinmedi; sunucu açılınca sonraki açılışta yeniden denenir
    }
  }

  @override
  Future<void> signOut() async {
    final refreshToken = await _store.read();
    _access = null;
    await _store.clear();
    if (refreshToken == null) return;
    try {
      await _dio.post<dynamic>('/api/Auth/logout', data: {'refreshToken': refreshToken});
    } on DioException {
      // sunucuya ulaşılamadı; yerel çıkış yapıldı, token süresi dolunca kendiliğinden biter
    }
  }

  Future<AuthUser> _me({String? fallbackEmail}) async {
    final me = _ok(await _call(() => _dio.get<dynamic>('/api/Users/me')));
    final name = '${me['firstName'] ?? ''} ${me['lastName'] ?? ''}'.trim();
    return AuthUser(fullName: name, email: (me['email'] as String?) ?? fallbackEmail ?? '');
  }

  Future<void> _storeTokens(Map<String, dynamic> body) async {
    _access = body['accessToken'] as String;
    final refreshToken = body['refreshToken'];
    if (refreshToken is String && refreshToken.isNotEmpty) await _store.save(refreshToken);
  }

  void _attachToken(RequestOptions o, RequestInterceptorHandler h) {
    if (_access != null && !_isAuthPath(o.path)) o.headers['Authorization'] = 'Bearer $_access';
    h.next(o);
  }

  Future<void> _retryOn401(Response<dynamic> res, ResponseInterceptorHandler h) async {
    final o = res.requestOptions;
    if (res.statusCode != 401 || _access == null || _isAuthPath(o.path) || o.extra['retried'] == true) return h.next(res);
    try {
      // Başka bir istek token'ı zaten yenilediyse yenilemeden tekrar dene
      final stale = o.headers['Authorization'] != 'Bearer $_access';
      if (!stale && !await _refresh()) {
        onSessionExpired?.call();
        return h.next(res);
      }
      o.extra['retried'] = true;
      o.headers['Authorization'] = 'Bearer $_access';
      h.resolve(await _dio.fetch<dynamic>(o));
    } on NetworkFailure {
      h.next(res); // yenileme için sunucuya ulaşılamadı; oturumu düşürme
    } on DioException catch (e) {
      h.reject(e);
    }
  }

  /// Aynı anda gelen 401'ler tek yenilemeyi paylaşır. Refresh token geçersizse false döner.
  Future<bool> _refresh() => _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);

  Future<bool> _doRefresh() async {
    final refreshToken = await _store.read();
    if (refreshToken == null) return false;
    final res = await _call(() => _dio.post<dynamic>('/api/Auth/refresh', data: {'refreshToken': refreshToken}));
    if (res.statusCode == 401) {
      _access = null;
      await _store.clear();
      return false;
    }
    await _storeTokens(_ok(res));
    return true;
  }

  bool _isAuthPath(String path) => path.startsWith('/api/Auth/');

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
