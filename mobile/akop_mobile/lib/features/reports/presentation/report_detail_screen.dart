import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/format.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_badge.dart';
import '../application/reports_controller.dart';
import '../domain/report.dart';
import 'report_map.dart';
import 'report_photo_view.dart';

/// C-08 İhbar detayı
class ReportDetailScreen extends ConsumerWidget {
  const ReportDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(reportByIdProvider(id));
    final loading = ref.watch(reportsProvider).isLoading;
    final appBar = AppBar(
      leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      title: const Text('İhbar Detayı'),
    );
    if (report == null) {
      return Scaffold(
        appBar: appBar,
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : const EmptyState(icon: Icons.search_off, title: 'İhbar bulunamadı', message: 'Bu ihbar silinmiş ya da erişiminiz yok.'),
      );
    }

    final action = switch (report.status) {
      ReportStatus.resolvedPendingConfirmation => ('Çözümü doğrula', '/ihbar/$id/dogrula'),
      ReportStatus.needsCitizenInfo => ('Ek bilgi ver', '/ihbar/$id/ek-bilgi'),
      _ => null,
    };

    return Scaffold(
      appBar: appBar,
      body: ListView(
        padding: EdgeInsets.only(bottom: action == null ? 24 : 96),
        children: [
          _Gallery(photos: report.photos),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.surfaceTint, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(child: StatusBadge(label: report.status.label(report.organization), tone: report.status.tone, icon: report.status.icon)),
                          const SizedBox(width: 8),
                          const Text('Güncel durum', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(report.status.nextStep, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(report.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.25)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _Meta(Icons.schedule, formatLong(report.createdAt)),
                    _Meta(Icons.place_outlined, report.locationLabel),
                  ],
                ),
                const SizedBox(height: 12),
                Text(report.description, style: const TextStyle(color: AppColors.textSecondary, height: 1.5)),
                if (report.organization != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(color: AppColors.surfaceTint, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.account_balance_outlined, color: AppColors.navy),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Sorumlu kurum', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            Text(report.organization!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                StaticReportMap(center: LatLng(report.lat, report.lng)),
                const SizedBox(height: 24),
                const Text('Süreç', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                _Timeline(report: report),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: action == null
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.border))),
              child: SafeArea(
                top: false,
                child: FilledButton(onPressed: () => context.push(action.$2), child: Text(action.$1)),
              ),
            ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ],
      );
}

class _Gallery extends StatefulWidget {
  const _Gallery({required this.photos});

  final List<ReportPhoto> photos;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos.isEmpty ? const [ReportPhoto()] : widget.photos;
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Stack(
        children: [
          PageView(
            onPageChanged: (i) => setState(() => _page = i),
            children: [for (final p in photos) ReportPhotoView(p)],
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppColors.navy.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(12)),
              child: Text('${_page + 1}/${photos.length}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
          if (photos.length > 1)
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < photos.length; i++)
                    Container(
                      width: i == _page ? 18 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(color: i == _page ? Colors.white : Colors.white54, borderRadius: BorderRadius.circular(3)),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.report});

  final Report report;

  @override
  Widget build(BuildContext context) {
    final closed = report.status == ReportStatus.closed;
    final entries = report.timeline;
    final upcoming = switch (report.status) {
      ReportStatus.accepted || ReportStatus.inProgress || ReportStatus.reopened => true,
      _ => false,
    };
    final total = entries.length + (upcoming ? 1 : 0);
    return Column(
      children: [
        for (var i = 0; i < entries.length; i++)
          _Step(
            label: entries[i].label,
            subtitle: formatShort(entries[i].at),
            state: (!closed && i == entries.length - 1) ? _StepState.current : _StepState.done,
            last: i == total - 1,
          ),
        if (upcoming) const _Step(label: 'Çözüm doğrulaması', subtitle: 'Bekleniyor', state: _StepState.upcoming, last: true),
      ],
    );
  }
}

enum _StepState { done, current, upcoming }

class _Step extends StatelessWidget {
  const _Step({required this.label, required this.subtitle, required this.state, required this.last});

  final String label;
  final String subtitle;
  final _StepState state;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final upcoming = state == _StepState.upcoming;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                switch (state) {
                  _StepState.done => Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(color: AppColors.navy, shape: BoxShape.circle),
                      child: const Icon(Icons.check, size: 15, color: Colors.white),
                    ),
                  _StepState.current => Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(color: AppColors.infoBg, shape: BoxShape.circle),
                      child: Center(child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.navy, shape: BoxShape.circle))),
                    ),
                  _StepState.upcoming => Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(color: AppColors.neutralBg, shape: BoxShape.circle),
                      child: Center(child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.border, shape: BoxShape.circle))),
                    ),
                },
                if (!last) Expanded(child: Container(width: 2, color: upcoming ? AppColors.border : AppColors.navy)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontWeight: upcoming ? FontWeight.w500 : FontWeight.w700, color: upcoming ? AppColors.textSecondary : AppColors.text)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
