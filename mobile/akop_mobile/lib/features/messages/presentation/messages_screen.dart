import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Mesajlaşma API'si hazır olana kadar yalnızca boş durum gösterilir.
class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mesajlar')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.textSecondary),
              SizedBox(height: 16),
              Text('Henüz mesajınız yok', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text('Mesajlarınız burada görünecek.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
