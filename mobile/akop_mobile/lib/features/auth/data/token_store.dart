import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Yalnız refresh token kalıcı saklanır; access token kısa ömürlü olduğu için bellekte kalır.
abstract interface class TokenStore {
  Future<String?> read();
  Future<void> save(String refreshToken);
  Future<void> clear();
}

/// Android Keystore / iOS Keychain üzerinde saklar.
class SecureTokenStore implements TokenStore {
  static const _key = 'refresh_token';
  final _storage = const FlutterSecureStorage();

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> save(String refreshToken) => _storage.write(key: _key, value: refreshToken);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}
