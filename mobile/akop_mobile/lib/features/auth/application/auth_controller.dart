import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/api_config.dart';
import '../data/api_auth_repository.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => ApiAuthRepository(
    Dio(BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      // 400/401 yanıtlarını repository kendisi ele alır
      validateStatus: (s) => s != null && s < 500,
    )),
  ),
);

class AuthState {
  const AuthState({this.user, this.loading = false, this.error});

  final AuthUser? user;
  final bool loading;
  final String? error;

  bool get isLoggedIn => user != null;
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<void> signIn(String email, String password) => _run(() => _repo.signIn(email, password));

  Future<void> register(String firstName, String lastName, String email, String password) =>
      _run(() => _repo.register(firstName, lastName, email, password));

  Future<void> _run(Future<AuthUser> Function() action) async {
    state = const AuthState(loading: true);
    try {
      state = AuthState(user: await action());
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

  void signOut() => state = const AuthState();

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
