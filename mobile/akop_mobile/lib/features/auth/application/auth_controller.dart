import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/api_config.dart';
import '../data/api_auth_repository.dart';
import '../data/auth_repository.dart';
import '../data/token_store.dart';

/// Tüm servisler bu Dio'yu paylaşır: [ApiAuthRepository] buna token ekleyen ve 401'de yenileyen
/// interceptor'ı takar. Başka servislere tam URL ile istek atılır.
final apiDioProvider = Provider<Dio>(
  (ref) => Dio(BaseOptions(
    baseUrl: apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    // 400/401 yanıtlarını repository kendisi ele alır
    validateStatus: (s) => s != null && s < 500,
  )),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => ApiAuthRepository(ref.watch(apiDioProvider), SecureTokenStore()),
);

class AuthState {
  const AuthState({this.user, this.loading = false, this.restoring = false, this.error});

  final AuthUser? user;
  final bool loading;

  /// Uygulama açılırken saklı oturum aranıyor.
  final bool restoring;
  final String? error;

  bool get isLoggedIn => user != null;
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    _repo.onSessionExpired = () => state = const AuthState(); // giriş ekranına döner
    Future.microtask(_restore);
    return const AuthState(restoring: true);
  }

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<void> _restore() async {
    final user = await _repo.restoreSession();
    if (user != null && !user.role.usesMobileApp) {
      unawaited(_repo.signOut());
      state = const AuthState();
      return;
    }
    state = AuthState(user: user);
  }

  Future<void> signIn(String email, String password) => _run(() => _repo.signIn(email, password));

  Future<void> register(String firstName, String lastName, String email, String password) =>
      _run(() => _repo.register(firstName, lastName, email, password));

  Future<void> _run(Future<AuthUser> Function() action) async {
    state = const AuthState(loading: true);
    try {
      final user = await action();
      if (user.role.usesMobileApp) {
        state = AuthState(user: user);
      } else {
        // Kurum yöneticisi ve sistem yöneticisi web panelini kullanır
        unawaited(_repo.signOut());
        state = const AuthState(error: 'Bu hesap mobil uygulamada kullanılamıyor. Web panelinden giriş yapın.');
      }
    } on InvalidCredentials {
      state = const AuthState(error: 'E-posta veya parola hatalı.');
    } on EmailTaken {
      state = const AuthState(error: 'Bu e-posta ile kayıtlı bir hesap var.');
    } on RegisterRejected catch (e) {
      state = AuthState(error: e.messages.isEmpty ? 'Kayıt yapılamadı. Bilgilerinizi kontrol edin.' : e.messages.join('\n'));
    } on NetworkFailure {
      state = const AuthState(error: 'Sunucuya ulaşılamadı. Bağlantınızı kontrol edip tekrar deneyin.');
    }
  }

  void clearError() {
    if (state.error != null) state = AuthState(user: state.user);
  }

  /// Önce ekrandan çıkar, sunucuya haber verme arka planda sürer.
  void signOut() {
    state = const AuthState();
    unawaited(_repo.signOut());
  }

  void updateName(String fullName) {
    final u = state.user;
    if (u != null) state = AuthState(user: u.copyWith(fullName: fullName.trim()));
  }

  /// Mevcut parola yanlışsa false döner.
  Future<bool> changePassword(String current, String next) async {
    try {
      await _repo.changePassword(state.user!.email, current, next);
      return true;
    } on InvalidCredentials {
      return false;
    }
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);
