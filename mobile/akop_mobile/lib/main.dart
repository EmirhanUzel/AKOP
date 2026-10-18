import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const AKOPApp());
}

class AKOPApp extends StatelessWidget {
  const AKOPApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AKOP',
      debugShowCheckedModeBanner: false,

      // Oluşturduğumuz tema
      theme: AppTheme.lightTheme,

      home: Scaffold(
        appBar: AppBar(
          title: const Text('AKOP'),
        ),

        body: const Center(
          child: Text(
            'AKOP Mobil Uygulaması',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}