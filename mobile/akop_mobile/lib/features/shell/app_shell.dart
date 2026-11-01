import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../auth/application/auth_controller.dart';
import '../auth/data/auth_repository.dart';

/// Alt menü kabuğu. Sekmeler: ilk sekme • Mesajlar • Profil.
/// Vatandaşta ilk sekme İhbarlarım ve ortada İhbar Et butonu var; saha personelinde ilk sekme Görevler.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authControllerProvider.select((s) => s.user?.role));
    final canReport = role != UserRole.fieldStaff;
    final index = navigationShell.currentIndex;
    void open(int i) => navigationShell.goBranch(i, initialLocation: i == index);

    final home = _NavItem(
      icon: canReport ? Icons.assignment : Icons.engineering,
      label: canReport ? 'İhbarlarım' : 'Görevler',
      selected: index == 0,
      onTap: () => open(0),
    );
    final messages = _NavItem(icon: Icons.chat_bubble_outline, label: 'Mesajlar', selected: index == 1, onTap: () => open(1));
    final profile = _NavItem(icon: Icons.person_outline, label: 'Profil', selected: index == 2, onTap: () => open(2));

    return Scaffold(
      body: navigationShell,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: canReport
          ? FloatingActionButton(
              tooltip: 'İhbar Et',
              shape: const CircleBorder(),
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              elevation: 3,
              onPressed: () => context.push('/yeni/foto'),
              child: const Icon(Icons.add, size: 30),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.border))),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 72,
            child: canReport
                // Ortadaki buton için boşluk: solda İhbarlarım ve Mesajlar, sağda Profil
                ? Row(
                    children: [
                      Expanded(child: Row(children: [Expanded(child: home), Expanded(child: messages)])),
                      const SizedBox(
                        width: 72,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 10),
                            child: Text('İhbar Et', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.navy)),
                          ),
                        ),
                      ),
                      Expanded(child: Row(children: [Expanded(child: profile)])),
                    ],
                  )
                : Row(children: [Expanded(child: home), Expanded(child: messages), Expanded(child: profile)]),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.navy : AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 3),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(color: selected ? AppColors.orange : Colors.transparent, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}
