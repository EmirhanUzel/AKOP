import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../application/report_providers.dart';
import '../domain/report.dart';
import '../domain/report_category.dart';

/// "Az önce", "5 dk önce", "3 saat önce", "2 gün önce".
String relativeTime(DateTime time, DateTime now) {
  final diff = now.difference(time);
  if (diff.inMinutes < 1) return 'Az önce';
  if (diff.inHours < 1) return '${diff.inMinutes} dk önce';
  if (diff.inDays < 1) return '${diff.inHours} saat önce';
  return '${diff.inDays} gün önce';
}

class ReportCard extends ConsumerWidget {
  const ReportCard({super.key, required this.report, this.onTap});

  final Report report;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = categoryOf(ref.watch(reportCategoriesProvider).value, report.categoryCode);
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.border)),
      child: InkWell(
        onTap: onTap,
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppColors.infoBg,
            child: Icon(category?.icon ?? Icons.assignment_outlined, color: AppColors.navy),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                // Başlıksız ihbarda başlık zaten kategori adıdır; ikinci kez yazılmaz
                if (category != null && category.name != report.title) ...[
                  const SizedBox(height: 2),
                  Text(category.name, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(child: Text(report.locationText, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    StatusBadge(report.status),
                    const Spacer(),
                    Text(relativeTime(report.createdAt, DateTime.now()), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      ReportStatus.pending => (AppColors.warningBg, AppColors.warning),
      ReportStatus.inProgress => (AppColors.infoBg, AppColors.info),
      ReportStatus.resolved => (AppColors.successBg, AppColors.success),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(status.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}
