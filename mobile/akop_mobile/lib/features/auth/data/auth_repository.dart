class AuthUser {
  const AuthUser({required this.fullName, required this.email});

  final String fullName;
  final String email;

  AuthUser copyWith({String? fullName}) => AuthUser(fullName: fullName ?? this.fullName, email: email);
}

class InvalidCredentials implements Exception {}

class EmailTaken implements Exception {}

abstract interface class AuthRepository {
  /// Başarısız girişte [InvalidCredentials] fırlatır.
  Future<AuthUser> signIn(String email, String password);

  /// E-posta kayıtlıysa [EmailTaken] fırlatır.
  Future<AuthUser> register(String fullName, String email, String password);

  /// Mevcut parola yanlışsa [InvalidCredentials] fırlatır.
  Future<void> changePassword(String email, String current, String next);
}

/// API hazır olana kadar. Test hesabı: citizen@akop.test / 123456
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.delay = const Duration(milliseconds: 600)});

  final Duration delay;
  final Map<String, ({String name, String password})> _users = {
    'citizen@akop.test': (name: 'Ayşe Yılmaz', password: '123456'),
  };

  Future<void> _wait() => Future<void>.delayed(delay);

  @override
  Future<AuthUser> signIn(String email, String password) async {
    await _wait();
    final key = email.trim().toLowerCase();
    final u = _users[key];
    if (u == null || u.password != password) throw InvalidCredentials();
    return AuthUser(fullName: u.name, email: key);
  }

  @override
  Future<AuthUser> register(String fullName, String email, String password) async {
    await _wait();
    final key = email.trim().toLowerCase();
    if (_users.containsKey(key)) throw EmailTaken();
    _users[key] = (name: fullName.trim(), password: password);
    return AuthUser(fullName: fullName.trim(), email: key);
  }

  @override
  Future<void> changePassword(String email, String current, String next) async {
    await _wait();
    final u = _users[email];
    if (u == null || u.password != current) throw InvalidCredentials();
    _users[email] = (name: u.name, password: next);
  }
}
