import 'dart:convert';

import 'package:akop_mobile/features/auth/data/api_auth_repository.dart';
import 'package:akop_mobile/features/auth/data/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'memory_token_store.dart';

typedef _Reply = (int, Object?);

/// Her isteğe [handler] ile cevap verir ve istekleri kaydeder; ağ kullanmaz.
class _Adapter implements HttpClientAdapter {
  _Adapter(this.handler);

  final _Reply Function(RequestOptions) handler;
  final calls = <String>[];

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<List<int>>? body, Future<void>? cancel) async {
    calls.add('${o.method} ${o.path}');
    final (status, data) = handler(o);
    return ResponseBody.fromString(jsonEncode(data), status, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }

  @override
  void close({bool force = false}) {}
}

(ApiAuthRepository, _Adapter, MemoryTokenStore) _make(_Reply Function(RequestOptions) handler, {String? stored}) {
  final adapter = _Adapter(handler);
  final store = MemoryTokenStore(stored);
  final dio = Dio(BaseOptions(baseUrl: 'http://test', validateStatus: (s) => s != null && s < 500))..httpClientAdapter = adapter;
  return (ApiAuthRepository(dio, store), adapter, store);
}

_Reply _tokens(String access, String refresh) =>
    (200, {'accessToken': access, 'role': 'Citizen', 'expiresAtUtc': '2026-10-26T12:00:00Z', 'refreshToken': refresh});

const _me = (200, {'email': 'ali@akop.test', 'firstName': 'Ali', 'lastName': 'Veli', 'role': 'Citizen'});

void main() {
  test('giriş: refresh token saklanır', () async {
    final (repo, _, store) = _make((o) => o.path == '/api/Auth/login' ? _tokens('a1', 'r1') : _me);
    await repo.signIn('ali@akop.test', 'Sifre1.');
    expect(store.value, 'r1');
  });

  test('access token süresi dolunca (401) bir kez yenilenir ve istek tekrarlanır', () async {
    final (repo, adapter, store) = _make((o) {
      if (o.path == '/api/Auth/login') return _tokens('eski', 'r1');
      if (o.path == '/api/Auth/refresh') return _tokens('yeni', 'r2');
      return o.headers['Authorization'] == 'Bearer yeni' ? _me : (401, 'süresi doldu');
    });
    // giriş sırasındaki /me çağrısı da 401 alır, yenilenip tekrarlanır
    final u = await repo.signIn('ali@akop.test', 'Sifre1.');
    expect(u.fullName, 'Ali Veli');
    expect(store.value, 'r2');
    expect(adapter.calls.where((c) => c == 'POST /api/Auth/refresh').length, 1);
    expect(adapter.calls.where((c) => c == 'GET /api/Users/me').length, 2); // 401 + tekrar
  });

  test('refresh token geçersizse oturum düşer, token silinir', () async {
    var expired = 0;
    final (repo, _, store) = _make((o) {
      if (o.path == '/api/Auth/login') return _tokens('eski', 'r1');
      if (o.path == '/api/Auth/refresh') return (401, 'geçersiz');
      return (401, 'süresi doldu');
    });
    repo.onSessionExpired = () => expired++;
    await expectLater(repo.signIn('a@b.co', 'x'), throwsA(isA<NetworkFailure>()));
    expect(expired, 1);
    expect(store.value, isNull);
  });

  test('açılışta saklı refresh token ile oturum sessizce açılır', () async {
    final (repo, adapter, store) = _make((o) => o.path == '/api/Auth/refresh' ? _tokens('a2', 'r2') : _me, stored: 'r1');
    final u = await repo.restoreSession();
    expect(u?.fullName, 'Ali Veli');
    expect(store.value, 'r2');
    expect(adapter.calls, ['POST /api/Auth/refresh', 'GET /api/Users/me']);
  });

  test('açılışta saklı token yoksa ya da geçersizse null döner', () async {
    final (none, _, _) = _make((_) => _me);
    expect(await none.restoreSession(), isNull);

    final (bad, _, store) = _make((_) => (401, 'geçersiz'), stored: 'r1');
    expect(await bad.restoreSession(), isNull);
    expect(store.value, isNull);
  });

  test('çıkış: sunucuya refresh token ile haber verir ve yerel oturumu siler', () async {
    late RequestOptions logout;
    final (repo, adapter, store) = _make((o) {
      if (o.path == '/api/Auth/logout') {
        logout = o;
        return (204, null);
      }
      return o.path == '/api/Auth/login' ? _tokens('a1', 'r1') : _me;
    });
    await repo.signIn('a@b.co', 'x');
    await repo.signOut();
    expect(logout.data, {'refreshToken': 'r1'});
    expect(store.value, isNull);
    expect(adapter.calls.last, 'POST /api/Auth/logout');
  });

  test('çıkış: sunucu kapalıysa da yerel oturum silinir', () async {
    final (repo, _, store) = _make((o) => throw DioException.connectionError(requestOptions: o, reason: 'kapalı'), stored: 'r1');
    await repo.signOut();
    expect(store.value, isNull);
  });
}
