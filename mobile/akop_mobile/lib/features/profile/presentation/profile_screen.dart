import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    if (user == null) return const SizedBox.shrink(); // çıkış sırasında kısa süre

    final name = user.fullName.trim();
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.infoBg,
              child: Text(
                name.isEmpty ? '?' : name[0].toUpperCase(),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: AppColors.navy),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(user.email, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: AppColors.neutralBg, borderRadius: BorderRadius.circular(12)),
              child: Text(user.role.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            ),
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: ref.read(authControllerProvider.notifier).signOut,
            icon: const Icon(Icons.logout),
            label: const Text('Çıkış yap'),
          ),
        ],
      ),
    );
  }
}
