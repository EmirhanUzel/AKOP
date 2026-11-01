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
            Image(image: AssetImage('assets/images/akop_logo.png'), height: 64),
            SizedBox(height: 24),
            CircularProgressIndicator(color: AppColors.navy),
          ],
        ),
      ),
    );
  }
}
