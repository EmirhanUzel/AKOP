import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../reports/application/draft_controller.dart';

/// Vatandaş kabuğu: İhbarlarım • İhbar Et (ortada) • Profil.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: shell,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        tooltip: 'İhbar Et',
        shape: const CircleBorder(),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 3,
        onPressed: () {
          ref.read(draftProvider.notifier).reset();
          context.push('/yeni/foto');
        },
        child: const Icon(Icons.add, size: 30),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.border))),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 72,
            child: Row(
              children: [
                Expanded(
                  child: _NavItem(
                    icon: Icons.assignment_outlined,
                    selectedIcon: Icons.assignment,
                    label: 'İhbarlarım',
                    selected: shell.currentIndex == 0,
                    onTap: () => shell.goBranch(0, initialLocation: shell.currentIndex == 0),
                  ),
                ),
                const Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Text('İhbar Et', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.navy)),
                    ),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.person_outline,
                    selectedIcon: Icons.person,
                    label: 'Profil',
                    selected: shell.currentIndex == 1,
                    onTap: () => shell.goBranch(1, initialLocation: shell.currentIndex == 1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.selectedIcon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final IconData selectedIcon;
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
          Icon(selected ? selectedIcon : icon, color: color),
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
