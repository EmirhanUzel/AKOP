import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/profile/presentation/change_password_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/reports/presentation/additional_info_screen.dart';
import '../../features/reports/presentation/confirm_resolution_screen.dart';
import '../../features/reports/presentation/new_report/detail_step.dart';
import '../../features/reports/presentation/new_report/location_step.dart';
import '../../features/reports/presentation/new_report/photo_step.dart';
import '../../features/reports/presentation/new_report/summary_step.dart';
import '../../features/reports/presentation/report_detail_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/shell/app_shell.dart';

const _authPaths = {'/giris', '/kayit'};

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (prev, next) {
    if (prev?.isLoggedIn != next.isLoggedIn) refresh.value++;
  });
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/giris',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loggedIn = ref.read(authControllerProvider).isLoggedIn;
      final atAuth = _authPaths.contains(state.matchedLocation);
      if (!loggedIn) return atAuth ? null : '/giris';
      return atAuth ? '/' : null;
    },
    routes: [
      GoRoute(path: '/giris', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/kayit', builder: (_, _) => const RegisterScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/', builder: (_, _) => const ReportsScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profil', builder: (_, _) => const ProfileScreen())]),
        ],
      ),
      GoRoute(path: '/profil/parola', builder: (_, _) => const ChangePasswordScreen()),
      GoRoute(path: '/ihbar/:id', builder: (_, s) => ReportDetailScreen(id: s.pathParameters['id']!)),
      GoRoute(path: '/ihbar/:id/dogrula', builder: (_, s) => ConfirmResolutionScreen(id: s.pathParameters['id']!)),
      GoRoute(path: '/ihbar/:id/ek-bilgi', builder: (_, s) => AdditionalInfoScreen(id: s.pathParameters['id']!)),
      GoRoute(path: '/yeni/foto', builder: (_, _) => const PhotoStep()),
      GoRoute(path: '/yeni/konum', builder: (_, _) => const LocationStep()),
      GoRoute(path: '/yeni/detay', builder: (_, _) => const DetailStep()),
      GoRoute(path: '/yeni/ozet', builder: (_, _) => const SummaryStep()),
    ],
  );
});
