import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/form_fields.dart';
import '../application/draft_controller.dart';
import '../application/reports_controller.dart';
import 'new_report/photo_widgets.dart';

/// C-09 Ek bilgi ver (durum: NeedsCitizenInfo)
class AdditionalInfoScreen extends ConsumerStatefulWidget {
  const AdditionalInfoScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<AdditionalInfoScreen> createState() => _AdditionalInfoScreenState();
}

class _AdditionalInfoScreenState extends ConsumerState<AdditionalInfoScreen> {
  final _text = TextEditingController();
  final List<String> _photos = [];
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _canSend => _text.text.trim().isNotEmpty || _photos.isNotEmpty;

  Future<void> _camera() async {
    if (_photos.length >= maxPhotos) return;
    final p = await pickFromCamera();
    if (p != null) setState(() => _photos.add(p));
  }

  Future<void> _gallery() async {
    final ps = await pickFromGallery(maxPhotos - _photos.length);
    if (ps.isNotEmpty) setState(() => _photos.addAll(ps));
  }

  Future<void> _send() async {
    setState(() => _busy = true);
    await ref.read(reportsProvider.notifier).provideInfo(widget.id, text: _text.text.trim(), photos: _photos);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    context.pop();
    messenger.showSnackBar(const SnackBar(content: Text('Bilgileriniz iletildi. İhbarınız yeniden değerlendirilecek.')));
  }

  @override
  Widget build(BuildContext context) {
    final full = _photos.length >= maxPhotos;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Ek bilgi ver'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.warning)),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('Doğru kuruma ulaşmak için ek bilgiye ihtiyaç var.', style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const FieldLabel('Ek açıklama'),
          TextField(
            controller: _text,
            maxLines: 5,
            minLines: 4,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'Eklemek istediğiniz bilgiyi yazın'),
          ),
          const SizedBox(height: 20),
          const FieldLabel('Ek fotoğraf', optional: true),
          if (_photos.isNotEmpty) PhotoStrip(photos: _photos, onRemove: (i) => setState(() => _photos.removeAt(i))),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: full ? null : _camera,
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), foregroundColor: AppColors.navy, side: const BorderSide(color: AppColors.border)),
                  icon: const Icon(Icons.photo_camera_outlined, size: 18),
                  label: const Text('Fotoğraf çek'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: full ? null : _gallery,
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), foregroundColor: AppColors.navy, side: const BorderSide(color: AppColors.border)),
                  icon: const Icon(Icons.image_outlined, size: 18),
                  label: const Text('Galeriden seç'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Açıklama yazın ya da fotoğraf ekleyin.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.border))),
        child: SafeArea(
          top: false,
          child: FilledButton(
            onPressed: (_canSend && !_busy) ? _send : null,
            child: _busy
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Gönder'),
          ),
        ),
      ),
    );
  }
}
