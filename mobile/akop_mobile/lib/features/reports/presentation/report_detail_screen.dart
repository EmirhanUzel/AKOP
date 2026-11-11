import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../application/report_providers.dart';
import '../domain/report.dart';
import '../domain/report_category.dart';
import 'report_card.dart';

/// İhbar detayı: fotoğraflar (kaydırılır), durum, açıklama ve konum. Liste ekranındaki [Report] ile açılır.
class ReportDetailScreen extends ConsumerWidget {
  const ReportDetailScreen({super.key, required this.report});

  final Report report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = categoryOf(ref.watch(reportCategoriesProvider).value, report.categoryCode);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back), tooltip: 'Geri', onPressed: () => context.pop()),
        title: const Text('İhbar detayı'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (report.imageUrls.isNotEmpty) ...[_PhotoPager(paths: report.imageUrls), const SizedBox(height: 16)],
          Text(report.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.navy, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            children: [
              StatusBadge(report.status),
              const Spacer(),
              Text(relativeTime(report.createdAt, DateTime.now()), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          if (category != null) ...[
            const SizedBox(height: 12),
            Chip(
              avatar: Icon(category.icon, size: 16, color: AppColors.navy),
              label: Text(category.name),
              backgroundColor: AppColors.neutralBg,
              side: BorderSide.none,
              shape: const StadiumBorder(),
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
          if (report.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Açıklama', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(report.description, style: const TextStyle(color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 16),
          const Text('Konum', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.place_outlined, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(child: Text(report.locationText, style: const TextStyle(color: AppColors.textSecondary))),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhotoPager extends StatefulWidget {
  const _PhotoPager({required this.paths});

  final List<String> paths;

  @override
  State<_PhotoPager> createState() => _PhotoPagerState();
}

class _PhotoPagerState extends State<_PhotoPager> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 260,
        child: Stack(
          children: [
            PageView.builder(
              itemCount: widget.paths.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) => _Photo(path: widget.paths[i]),
            ),
            if (widget.paths.length > 1)
              Positioned(
                right: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                  child: Text('${_page + 1} / ${widget.paths.length}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Photo extends ConsumerWidget {
  const _Photo({required this.path});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const failed = ColoredBox(
      color: AppColors.neutralBg,
      child: Center(child: Text('Fotoğraf yüklenemedi', style: TextStyle(color: AppColors.textSecondary))),
    );
    return ref.watch(reportImageProvider(path)).when(
          loading: () => const ColoredBox(color: AppColors.neutralBg, child: Center(child: CircularProgressIndicator(color: AppColors.navy))),
          error: (_, _) => failed,
          data: (bytes) => Image.memory(bytes, fit: BoxFit.cover, width: double.infinity, errorBuilder: (_, _, _) => failed),
        );
  }
}
