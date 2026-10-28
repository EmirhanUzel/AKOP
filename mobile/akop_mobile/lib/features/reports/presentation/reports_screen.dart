import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';

/// İhbar listesi API'si hazır olana kadar yalnızca filtre çipleri ve boş durum gösterilir.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  static const _filters = ['Tümü', 'Devam eden', 'Onay bekleyen', 'Çözülen'];

  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İhbarlarım'),
        // Profil sayfası gelene kadar geçici çıkış yolu.
        actions: [IconButton(tooltip: 'Çıkış yap', icon: const Icon(Icons.logout), onPressed: ref.read(authControllerProvider.notifier).signOut)],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => _FilterChip(label: _filters[i], selected: i == _selected, onTap: () => setState(() => _selected = i)),
            ),
          ),
          const Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.assignment_outlined, size: 64, color: AppColors.textSecondary),
                    SizedBox(height: 16),
                    Text('Henüz ihbarınız yok', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                    SizedBox(height: 8),
                    Text('İlk ihbarınızı oluşturarak başlayın.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.navy : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.navy : AppColors.border),
        ),
        child: Row(
          children: [
            if (selected) const Padding(padding: EdgeInsets.only(right: 6), child: Icon(Icons.check, size: 16, color: Colors.white)),
            Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.textSecondary)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(color: selected ? Colors.white24 : AppColors.neutralBg, borderRadius: BorderRadius.circular(10)),
              child: Text('0', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}
