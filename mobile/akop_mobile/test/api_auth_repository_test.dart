import 'dart:convert';

import 'package:akop_mobile/features/auth/data/api_auth_repository.dart';
import 'package:akop_mobile/features/auth/data/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'memory_token_store.dart';

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
  return (ApiAuthRepository(dio, MemoryTokenStore()), adapter);
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

  test('giriş: me cevabındaki rol kullanıcıya aktarılır', () async {
    for (final (apiRole, expected) in [('Citizen', UserRole.citizen), ('FieldStaff', UserRole.fieldStaff), ('OrgManager', UserRole.other)]) {
      final (repo, _) = _repo({
        'POST /api/Auth/login': _loginOk,
        'GET /api/Users/me': (200, {'email': 'a@akop.test', 'firstName': 'A', 'lastName': 'B', 'role': apiRole}),
      });
      expect((await repo.signIn('a@akop.test', 'Sifre1!')).role, expected, reason: apiRole);
    }
  });

  test('parola değiştirme: PUT atar, sonra yeni parolayla giriş yapıp tokenları yeniler', () async {
    final (repo, adapter) = _repo({'PUT /api/Users/me/password': (204, null), 'POST /api/Auth/login': _loginOk});
    await repo.changePassword('ali@akop.test', 'Eski1!', 'Yeni1!x');
    expect(adapter.calls.map((c) => '${c.method} ${c.path}'), ['PUT /api/Users/me/password', 'POST /api/Auth/login']);
    expect(adapter.calls.first.data, {'currentPassword': 'Eski1!', 'newPassword': 'Yeni1!x'});
    expect(adapter.calls.last.data, {'email': 'ali@akop.test', 'password': 'Yeni1!x'});
  });

  test('parola değiştirme: yanlış mevcut parola InvalidCredentials verir ve yeniden giriş yapmaz', () async {
    final (repo, adapter) = _repo({
      'PUT /api/Users/me/password': (400, [
        {'code': 'PasswordMismatch', 'description': 'Incorrect password.'},
      ]),
    });
    await expectLater(repo.changePassword('a@b.co', 'yanlis', 'Yeni1!x'), throwsA(isA<InvalidCredentials>()));
    expect(adapter.calls, hasLength(1));
  });

  test('parola değiştirme: parola kuralı hataları Türkçe PasswordRejected olur', () async {
    final (repo, _) = _repo({
      'PUT /api/Users/me/password': (400, [
        {'code': 'PasswordRequiresUpper', 'description': 'Passwords must have at least one uppercase (A-Z).'},
        {'code': 'PasswordTooShort', 'description': 'Passwords must be at least 6 characters.'},
      ]),
    });
    await expectLater(
      repo.changePassword('a@b.co', 'Eski1!', 'abc'),
      throwsA(isA<PasswordRejected>().having((e) => e.messages, 'messages', ['Parola en az bir büyük harf içermeli.', 'Parola en az 6 karakter olmalı.'])),
    );
  });

  test('parola değiştirme: sunucu kapalıysa NetworkFailure verir', () async {
    final (repo, _) = _repo({});
    expect(repo.changePassword('a@b.co', 'Eski1!', 'Yeni1!x'), throwsA(isA<NetworkFailure>()));
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
