import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => FakeAuthRepository());

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

  Future<void> signIn(String email, String password) async {
    state = const AuthState(loading: true);
    try {
      state = AuthState(user: await _repo.signIn(email, password));
    } on InvalidCredentials {
      state = const AuthState(error: 'E-posta veya parola hatalı.');
    }
  }

  Future<void> register(String fullName, String email, String password) async {
    state = const AuthState(loading: true);
    try {
      state = AuthState(user: await _repo.register(fullName, email, password));
    } on EmailTaken {
      state = const AuthState(error: 'Bu e-posta ile kayıtlı bir hesap var.');
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
