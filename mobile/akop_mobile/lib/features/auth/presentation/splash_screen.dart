import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Açılışta saklı oturum aranırken gösterilir.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'AKOP',
              style: TextStyle(color: AppColors.navy, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 1.6),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(color: AppColors.navy),
          ],
        ),
      ),
    );
  }
}
