import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_badge.dart';
import '../application/reports_controller.dart';
import '../domain/report.dart';
import '../domain/report_category.dart';
import 'report_photo_view.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  ReportFilter _filter = ReportFilter.all;

  void _startNew() {
    context.push('/yeni/foto'); // ihbar akışı sonraki PR'da
  }

  @override
  Widget build(BuildContext context) {
    final reports = ref.watch(reportsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('İhbarlarım')),
      body: reports.when(
        loading: () => const _Skeleton(),
        error: (_, _) => ErrorState(title: 'İhbarlar yüklenemedi', onRetry: () => ref.invalidate(reportsProvider)),
        data: (all) {
          if (all.isEmpty) {
            return EmptyState(
              icon: Icons.assignment_outlined,
              title: 'Henüz ihbarınız yok',
              message: 'İlk ihbarınızı oluşturarak başlayın.',
              actionLabel: 'İhbar Et',
              onAction: _startNew,
            );
          }
          final shown = all.where((r) => _filter.matches(r.status)).toList();
          return Column(
            children: [
              _FilterRow(
                selected: _filter,
                counts: {for (final f in ReportFilter.values) f: all.where((r) => f.matches(r.status)).length},
                onSelected: (f) => setState(() => _filter = f),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: ref.read(reportsProvider.notifier).refresh,
                  child: shown.isEmpty
                      ? ListView(children: const [
                          SizedBox(height: 120),
                          EmptyState(icon: Icons.filter_list, title: 'Bu filtrede ihbar yok', message: 'Başka bir filtre seçin.'),
                        ])
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                          itemCount: shown.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (_, i) => _ReportCard(report: shown[i]),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.selected, required this.counts, required this.onSelected});

  final ReportFilter selected;
  final Map<ReportFilter, int> counts;
  final ValueChanged<ReportFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: ReportFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = ReportFilter.values[i];
          final on = f == selected;
          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => onSelected(f),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: on ? AppColors.navy : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: on ? AppColors.navy : AppColors.border),
              ),
              child: Row(
                children: [
                  if (on) const Padding(padding: EdgeInsets.only(right: 6), child: Icon(Icons.check, size: 16, color: Colors.white)),
                  Text(f.label, style: TextStyle(fontWeight: FontWeight.w600, color: on ? Colors.white : AppColors.textSecondary)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                    decoration: BoxDecoration(
                      color: on ? Colors.white24 : AppColors.neutralBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${counts[f]}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: on ? Colors.white : AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});

  final Report report;

  @override
  Widget build(BuildContext context) {
    final awaiting = report.status == ReportStatus.resolvedPendingConfirmation;
    final cat = categoryOf(report.categoryCode);
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.border)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/ihbar/${report.id}'), // detay sonraki PR'da
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: report.photos.isEmpty ? const ReportPhotoView(ReportPhoto()) : ReportPhotoView(report.photos.first),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(report.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.25)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(cat?.icon ?? Icons.place_outlined, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(report.locationLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (awaiting)
                          Text(formatShort(report.createdAt), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))
                        else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Flexible(
                                child: StatusBadge(
                                  label: report.status.label(report.organization),
                                  tone: report.status.tone,
                                  icon: report.status.icon,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(formatShort(report.createdAt), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (awaiting) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                  decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      Icon(report.status.icon, size: 18, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(report.status.label(null), style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.w700)),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.warning,
                          minimumSize: const Size(0, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        onPressed: () => context.push('/ihbar/${report.id}/dogrula'),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [Text('Doğrula'), SizedBox(width: 6), Icon(Icons.arrow_forward, size: 16)]),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        for (var i = 0; i < 5; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: const Row(
              children: [
                SkeletonBox(width: 80, height: 80),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(height: 16),
                      SizedBox(height: 8),
                      SkeletonBox(width: 140, height: 12),
                      SizedBox(height: 12),
                      SkeletonBox(width: 100, height: 24, radius: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
