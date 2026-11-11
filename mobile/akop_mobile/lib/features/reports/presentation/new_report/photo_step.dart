import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../application/draft_controller.dart';
import '../../application/report_providers.dart';
import 'photo_widgets.dart';
import 'step_scaffold.dart';

/// C-04 İhbar 1/4: Fotoğraf
class PhotoStep extends ConsumerWidget {
  const PhotoStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = ref.watch(draftProvider.select((d) => d.photos));
    final draft = ref.read(draftProvider.notifier);
    final full = photos.length >= maxPhotos;

    // Öneri ilk fotoğraf seçilir seçilmez istenir; sonuç Detay adımında kullanılır
    final query = photos.isEmpty ? null : (photo: photos.first, category: null);
    final suggesting = query != null && ref.watch(categorySuggestionProvider(query)).isLoading;
    if (query != null) {
      ref.listen(categorySuggestionProvider(query), (_, next) {
        if (next.isLoading) return;
        final d = ref.read(draftProvider);
        if (d.categoryCode != null && !d.categoryAuto) return; // kullanıcının seçimi korunur
        final s = next.value;
        if (s != null && s.isConfident && s.suggestions.isNotEmpty) {
          draft.setCategory(s.suggestions.first.code, auto: true);
        } else if (d.categoryAuto) {
          draft.setCategory(null); // ilk fotoğraf değişti, yeni fotoğraf için emin öneri yok
        }
      });
    }

    Future<void> camera() async {
      if (full) return;
      final p = await pickFromCamera();
      if (p != null) draft.addPhotos([p]);
    }

    Future<void> gallery() async {
      draft.addPhotos(await pickFromGallery(maxPhotos - photos.length));
    }

    return StepScaffold(
      step: 1,
      label: 'Fotoğraf',
      firstStep: true,
      buttonLabel: 'Devam',
      hint: photos.isEmpty ? 'En az 1 fotoğraf ekleyin.' : null,
      onNext: photos.isEmpty ? null : () => context.push('/yeni/konum'),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        children: [
          Text('Sorunu fotoğraflayın', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.navy, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Sorunun net göründüğü 1–5 fotoğraf ekleyin.', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          Semantics(
            button: true,
            label: 'Fotoğraf çek',
            child: InkWell(
              onTap: full ? null : camera,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: 200,
                decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(20)),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(radius: 32, backgroundColor: Colors.white24, child: Icon(Icons.photo_camera_outlined, color: Colors.white, size: 30)),
                    SizedBox(height: 12),
                    Text('Kamerayı açmak için dokunun', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    SizedBox(height: 2),
                    Text('Sorunu net gösterecek şekilde çekin', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: full ? null : camera,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Fotoğraf çek'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: full ? null : gallery,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    foregroundColor: AppColors.navy,
                    side: const BorderSide(color: AppColors.border),
                    backgroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Galeriden seç'),
                ),
              ),
            ],
          ),
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(child: Text('Seçilen fotoğraflar', style: TextStyle(fontWeight: FontWeight.w600))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.neutralBg, borderRadius: BorderRadius.circular(12)),
                        child: Text('${photos.length} / $maxPhotos fotoğraf', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  PhotoStrip(photos: photos, onRemove: draft.removePhoto, onAdd: full ? null : gallery),
                  if (suggesting) const Padding(padding: EdgeInsets.only(top: 8), child: SuggestingIndicator()),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
