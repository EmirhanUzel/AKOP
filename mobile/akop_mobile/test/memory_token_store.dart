import 'package:akop_mobile/features/auth/data/token_store.dart';

class MemoryTokenStore implements TokenStore {
  MemoryTokenStore([this.value]);

  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> save(String refreshToken) async => value = refreshToken;

  @override
  Future<void> clear() async => value = null;
}
