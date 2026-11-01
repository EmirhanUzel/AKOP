import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Görev atama API'si hazır olana kadar yalnızca boş durum gösterilir.
class FieldHomeScreen extends StatelessWidget {
  const FieldHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Görevler')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.engineering_outlined, size: 64, color: AppColors.textSecondary),
              SizedBox(height: 16),
              Text('Henüz görev atanmadı', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text('Size atanan işler burada görünecek.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
