import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../application/report_providers.dart';
import '../domain/report.dart';
import 'report_card.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  /// Tümü + durumlar; sıra çiplerin sırasıdır.
  static const List<ReportStatus?> _filters = [null, ReportStatus.inProgress, ReportStatus.pending, ReportStatus.resolved];

  int _selected = 0;

  static String _label(ReportStatus? s) => s?.label ?? 'Tümü';

  @override
  Widget build(BuildContext context) {
    final reports = ref.watch(myReportsProvider);
    final all = reports.asData?.value ?? const <Report>[];
    int count(ReportStatus? s) => s == null ? all.length : all.where((r) => r.status == s).length;

    return Scaffold(
      appBar: AppBar(title: const Text('İhbarlarım')),
      body: Column(
        children: [
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => _FilterChip(
                label: _label(_filters[i]),
                count: count(_filters[i]),
                selected: i == _selected,
                onTap: () => setState(() => _selected = i),
              ),
            ),
          ),
          Expanded(
            child: reports.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => _Message(
                icon: Icons.cloud_off_outlined,
                title: 'İhbarlar yüklenemedi',
                text: 'Bağlantınızı kontrol edip tekrar deneyin.',
                action: FilledButton(onPressed: () => ref.invalidate(myReportsProvider), child: const Text('Tekrar dene')),
              ),
              data: (list) {
                final status = _filters[_selected];
                final shown = status == null ? list : list.where((r) => r.status == status).toList();
                if (list.isEmpty) {
                  return const _Message(icon: Icons.assignment_outlined, title: 'Henüz ihbarınız yok', text: 'İlk ihbarınızı oluşturarak başlayın.');
                }
                if (shown.isEmpty) {
                  return _Message(icon: Icons.assignment_outlined, title: 'Bu durumda ihbarınız yok', text: '"${_label(status)}" durumunda ihbar bulunmuyor.');
                }
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(myReportsProvider.future),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96), // alttaki İhbar Et butonunun altında kalmasın
                    itemCount: shown.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => ReportCard(report: shown[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.title, required this.text, this.action});

  final IconData icon;
  final String title;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(text, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.count, required this.selected, required this.onTap});

  final String label;
  final int count;
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
              child: Text('$count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}
