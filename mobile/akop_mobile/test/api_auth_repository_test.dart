import 'dart:convert';

import 'package:akop_mobile/features/auth/data/api_auth_repository.dart';
import 'package:akop_mobile/features/auth/data/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// İstek yollarına göre hazır yanıt döner; hiçbir ağ kullanmaz.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.routes);

  final Map<String, (int, Object?)> routes;
  final calls = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? body, Future<void>? cancel) async {
    calls.add(options);
    final r = routes['${options.method} ${options.path}'];
    if (r == null) throw DioException.connectionError(requestOptions: options, reason: 'kapalı');
    return ResponseBody.fromString(jsonEncode(r.$2), r.$1, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }

  @override
  void close({bool force = false}) {}
}

(ApiAuthRepository, _FakeAdapter) _repo(Map<String, (int, Object?)> routes) {
  final adapter = _FakeAdapter(routes);
  final dio = Dio(BaseOptions(baseUrl: 'http://test', validateStatus: (s) => s != null && s < 500))..httpClientAdapter = adapter;
  return (ApiAuthRepository(dio), adapter);
}

const _loginOk = (200, {'accessToken': 'tok', 'role': 'Citizen', 'expiresAtUtc': '2026-10-23T12:00:00Z'});
const _meOk = (200, {'email': 'ali@akop.test', 'firstName': 'Ali', 'lastName': 'Veli', 'role': 'Citizen'});

void main() {
  test('giriş: token alır, me ile adı getirir ve sonraki isteklere token ekler', () async {
    final (repo, adapter) = _repo({'POST /api/Auth/login': _loginOk, 'GET /api/Users/me': _meOk});
    final u = await repo.signIn(' ali@akop.test ', 'Sifre1!');
    expect(u.fullName, 'Ali Veli');
    expect(u.email, 'ali@akop.test');
    expect(adapter.calls.first.data, {'email': 'ali@akop.test', 'password': 'Sifre1!'});
    expect(adapter.calls.last.headers['Authorization'], 'Bearer tok');
  });

  test('giriş: 401 InvalidCredentials verir', () async {
    final (repo, _) = _repo({'POST /api/Auth/login': (401, 'E-posta veya şifre hatalı')});
    expect(repo.signIn('a@b.co', 'x'), throwsA(isA<InvalidCredentials>()));
  });

  test('sunucu kapalıysa NetworkFailure verir', () async {
    final (repo, _) = _repo({});
    expect(repo.signIn('a@b.co', 'x'), throwsA(isA<NetworkFailure>()));
  });

  test('kayıt: ad ve soyadı ayrı gönderir, sonra giriş yapar', () async {
    final (repo, adapter) = _repo({
      'POST /api/Auth/register': (200, 'Kullanıcı Oluşturuldu'),
      'POST /api/Auth/login': _loginOk,
      'GET /api/Users/me': _meOk,
    });
    final u = await repo.register('Ali', 'Veli', 'ali@akop.test', 'Sifre1!');
    expect(adapter.calls.first.data, {'firstName': 'Ali', 'lastName': 'Veli', 'email': 'ali@akop.test', 'password': 'Sifre1!'});
    expect(u.fullName, 'Ali Veli');
  });

  test('kayıt: aynı e-posta EmailTaken verir', () async {
    final (repo, _) = _repo({
      'POST /api/Auth/register': (400, [
        {'code': 'DuplicateEmail', 'description': 'Bu e-posta adresi zaten kayıtlı.'},
      ]),
    });
    expect(repo.register('A', 'B', 'a@b.co', 'Sifre1!'), throwsA(isA<EmailTaken>()));
  });

  test('kayıt: parola kuralı mesajları RegisterRejected içinde gelir', () async {
    final (repo, _) = _repo({
      'POST /api/Auth/register': (400, [
        {'code': 'PasswordRequiresUpper', 'description': 'Passwords must have at least one uppercase (A-Z).'},
        {'code': 'PasswordRequiresDigit', 'description': 'Passwords must have at least one digit (0-9).'},
      ]),
    });
    await expectLater(
      repo.register('A', 'B', 'a@b.co', 'sifre'),
      throwsA(isA<RegisterRejected>().having((e) => e.messages, 'messages', ['Parola en az bir büyük harf içermeli.', 'Parola en az bir rakam içermeli.'])),
    );
  });

  test('kayıt: ASP.NET doğrulama hatası (errors haritası) mesajlara çevrilir', () async {
    final (repo, _) = _repo({
      'POST /api/Auth/register': (400, {
        'errors': {
          'Email': ['E-posta geçersiz.'],
        },
      }),
    });
    await expectLater(
      repo.register('A', 'B', 'yanlis', 'Sifre1!'),
      throwsA(isA<RegisterRejected>().having((e) => e.messages, 'messages', ['E-posta geçersiz.'])),
    );
  });
}
