import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/application/auth_controller.dart';

/// Giriş sonrası geçici ekran; ihbar listesi sonraki PR'da gelecek.
class HomePlaceholderScreen extends ConsumerWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    return Scaffold(
      appBar: AppBar(title: const Text('İhbarlarım')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Hoş geldiniz, ${user?.fullName ?? ''}'),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: ref.read(authControllerProvider.notifier).signOut,
              child: const Text('Çıkış yap'),
            ),
          ],
        ),
      ),
    );
  }
}
