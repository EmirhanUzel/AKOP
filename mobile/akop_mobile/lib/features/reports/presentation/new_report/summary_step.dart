import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../application/draft_controller.dart';
import '../../domain/report_category.dart';
import '../report_map.dart';
import 'step_scaffold.dart';

/// C-07 İhbar 4/4: Özet ve gönder
class SummaryStep extends ConsumerStatefulWidget {
  const SummaryStep({super.key});

  @override
  ConsumerState<SummaryStep> createState() => _SummaryStepState();
}

class _SummaryStepState extends ConsumerState<SummaryStep> {
  /// Özetten [steps] adım geri dönüp ilgili adımı açar.
  void _edit(int steps) {
    final nav = Navigator.of(context);
    var n = 0;
    nav.popUntil((_) => n++ >= steps);
  }

  /// Report API'si hazır olana kadar gönderim yok; taslak korunur.
  void _send() => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İhbar gönderimi henüz bağlı değil.')));

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(draftProvider);
    final cat = categoryOf(draft.categoryCode);
    final title = draft.title.trim();
    return StepScaffold(
      step: 4,
      label: 'Özet',
      buttonLabel: 'Gönder',
      buttonIcon: Icons.send_outlined,
      onNext: _send,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        children: [
          Text('İhbarınızı kontrol edin', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.navy, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _SummaryCard(
            title: 'Fotoğraflar',
            onEdit: () => _edit(3),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in draft.photos)
                  ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(p), width: 80, height: 80, fit: BoxFit.cover)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SummaryCard(
            title: 'Konum',
            onEdit: () => _edit(2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StaticReportMap(center: draft.location ?? defaultLocation, height: 120),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '${(draft.location ?? defaultLocation).latitude.toStringAsFixed(5)}, ${(draft.location ?? defaultLocation).longitude.toStringAsFixed(5)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SummaryCard(
            title: 'Açıklama',
            onEdit: () => _edit(1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700))),
                Text(draft.description.trim(), style: const TextStyle(color: AppColors.textSecondary)),
                if (cat != null) ...[
                  const SizedBox(height: 8),
                  Chip(
                    avatar: Icon(cat.icon, size: 16, color: AppColors.navy),
                    label: Text(cat.name),
                    backgroundColor: AppColors.neutralBg,
                    side: BorderSide.none,
                    shape: const StadiumBorder(),
                    labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(Icons.lock_outline, size: 18, color: AppColors.textSecondary),
              SizedBox(width: 8),
              Expanded(child: Text('Adınız ve iletişim bilgileriniz kurumlara gösterilmez.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary))),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.onEdit, required this.child});

  final String title;
  final VoidCallback onEdit;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
              TextButton(onPressed: onEdit, child: const Text('Düzenle')),
            ],
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}
