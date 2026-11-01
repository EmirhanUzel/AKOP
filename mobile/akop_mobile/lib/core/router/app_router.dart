import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/reports/presentation/new_report/detail_step.dart';
import '../../features/reports/presentation/new_report/location_step.dart';
import '../../features/reports/presentation/new_report/photo_step.dart';
import '../../features/reports/presentation/new_report/summary_step.dart';
import '../../features/profile/presentation/change_password_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/shell/role_home.dart';

const _authPaths = {'/giris', '/kayit'};
const _splash = '/yukleniyor';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (prev, next) {
    if (prev?.isLoggedIn != next.isLoggedIn || prev?.restoring != next.restoring) refresh.value++;
  });
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: _splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final here = state.matchedLocation;
      if (auth.restoring) return here == _splash ? null : _splash;
      final atAuth = _authPaths.contains(here);
      if (!auth.isLoggedIn) return atAuth ? null : '/giris';
      return (atAuth || here == _splash) ? '/' : null;
    },
    routes: [
      GoRoute(path: _splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/giris', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/kayit', builder: (_, _) => const RegisterScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/', builder: (_, _) => const RoleHome())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profil', builder: (_, _) => const ProfileScreen())]),
        ],
      ),
      GoRoute(path: '/profil/sifre', builder: (_, _) => const ChangePasswordScreen()),
      GoRoute(path: '/yeni/foto', builder: (_, _) => const PhotoStep()),
      GoRoute(path: '/yeni/konum', builder: (_, _) => const LocationStep()),
      GoRoute(path: '/yeni/detay', builder: (_, _) => const DetailStep()),
      GoRoute(path: '/yeni/ozet', builder: (_, _) => const SummaryStep()),
    ],
  );
});
