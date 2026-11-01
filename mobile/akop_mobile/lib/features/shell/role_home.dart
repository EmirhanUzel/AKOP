import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/application/auth_controller.dart';
import '../auth/data/auth_repository.dart';
import '../field/presentation/field_home_screen.dart';
import '../reports/presentation/reports_screen.dart';

/// Giriş yapan kullanıcının rolüne göre ilk sekmenin içeriğini seçer.
class RoleHome extends ConsumerWidget {
  const RoleHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authControllerProvider.select((s) => s.user?.role));
    return role == UserRole.fieldStaff ? const FieldHomeScreen() : const ReportsScreen();
  }
}
