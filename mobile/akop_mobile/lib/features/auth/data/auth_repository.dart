class AuthUser {
  const AuthUser({required this.fullName, required this.email});

  final String fullName;
  final String email;

  AuthUser copyWith({String? fullName}) => AuthUser(fullName: fullName ?? this.fullName, email: email);
}

class InvalidCredentials implements Exception {}

class EmailTaken implements Exception {}

/// Kayıt sunucu tarafından reddedildi (ör. parola kuralı); [messages] kullanıcıya gösterilir.
class RegisterRejected implements Exception {
  RegisterRejected(this.messages);

  final List<String> messages;
}

/// Sunucuya ulaşılamadı ya da sunucu hata verdi.
class NetworkFailure implements Exception {}

abstract interface class AuthRepository {
  /// Başarısız girişte [InvalidCredentials] fırlatır.
  Future<AuthUser> signIn(String email, String password);

  /// E-posta kayıtlıysa [EmailTaken], başka bir red için [RegisterRejected] fırlatır.
  /// Başarılıysa kullanıcı giriş yapmış olarak döner.
  Future<AuthUser> register(String firstName, String lastName, String email, String password);

  /// Mevcut parola yanlışsa [InvalidCredentials] fırlatır.
  Future<void> changePassword(String email, String current, String next);

  /// Telefonda saklı refresh token ile oturumu sessizce açar; token yoksa, geçersizse
  /// ya da sunucuya ulaşılamıyorsa null döner.
  Future<AuthUser?> restoreSession();

  /// Yerel oturumu siler ve sunucuya haber verir (sunucu kapalıysa yine de çıkış yapılır).
  Future<void> signOut();

  /// Access token yenilenemediğinde (refresh token geçersiz/süresi dolmuş) çağrılır.
  void Function()? onSessionExpired;
}

/// Test ve geliştirme için sahte sürüm. Test hesabı: citizen@akop.test / 123456
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.delay = const Duration(milliseconds: 600)});

  final Duration delay;
  final Map<String, ({String name, String password})> _users = {
    'citizen@akop.test': (name: 'Ayşe Yılmaz', password: '123456'),
  };

  @override
  void Function()? onSessionExpired;

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
  Future<AuthUser> register(String firstName, String lastName, String email, String password) async {
    await _wait();
    final key = email.trim().toLowerCase();
    if (_users.containsKey(key)) throw EmailTaken();
    final name = '${firstName.trim()} ${lastName.trim()}';
    _users[key] = (name: name, password: password);
    return AuthUser(fullName: name, email: key);
  }

  @override
  Future<void> changePassword(String email, String current, String next) async {
    await _wait();
    final u = _users[email];
    if (u == null || u.password != current) throw InvalidCredentials();
    _users[email] = (name: u.name, password: next);
  }

  @override
  Future<AuthUser?> restoreSession() async => null;

  @override
  Future<void> signOut() async {}
}
