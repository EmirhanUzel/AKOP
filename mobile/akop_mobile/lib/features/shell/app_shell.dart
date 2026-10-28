import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

/// Vatandaş kabuğu: İhbarlarım • İhbar Et (ortada) • Profil.
/// Sekmeler şimdilik yönlendirmez; yalnızca İhbar Et akışı açar.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        tooltip: 'İhbar Et',
        shape: const CircleBorder(),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 3,
        onPressed: () => context.push('/yeni/foto'),
        child: const Icon(Icons.add, size: 30),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.border))),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 72,
            child: Row(
              children: const [
                Expanded(child: _NavItem(icon: Icons.assignment, label: 'İhbarlarım', selected: true)),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Text('İhbar Et', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.navy)),
                    ),
                  ),
                ),
                Expanded(child: _NavItem(icon: Icons.person_outline, label: 'Profil', selected: false)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.selected});

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.navy : AppColors.textSecondary;
    return Column(
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
    );
  }
}
