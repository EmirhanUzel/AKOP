import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
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

class ReportCard extends StatelessWidget {
  const ReportCard({super.key, required this.report});

  final Report report;

  @override
  Widget build(BuildContext context) {
    final category = categoryOf(report.categoryCode);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
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
                if (category != null) ...[
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
                    _StatusBadge(report.status),
                    const Spacer(),
                    Text(relativeTime(report.createdAt, DateTime.now()), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status);

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
