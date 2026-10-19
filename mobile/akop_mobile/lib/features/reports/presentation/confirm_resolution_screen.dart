import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/form_fields.dart';
import '../../../core/widgets/status_badge.dart';
import '../application/reports_controller.dart';
import '../domain/report.dart';
import 'report_photo_view.dart';

/// C-10 Çözümü doğrula
class ConfirmResolutionScreen extends ConsumerStatefulWidget {
  const ConfirmResolutionScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<ConfirmResolutionScreen> createState() => _ConfirmResolutionScreenState();
}

class _ConfirmResolutionScreenState extends ConsumerState<ConfirmResolutionScreen> {
  bool? _resolved;
  bool _busy = false;
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    final resolved = _resolved!;
    await ref.read(reportsProvider.notifier).confirm(widget.id, resolved: resolved, comment: _comment.text.trim());
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    context.pop();
    messenger.showSnackBar(SnackBar(content: Text(resolved ? 'Teşekkürler, ihbarınız kapatıldı.' : 'Yanıtınız iletildi, ihbar yeniden açıldı.')));
  }

  @override
  Widget build(BuildContext context) {
    final report = ref.watch(reportByIdProvider(widget.id));
    final res = report?.resolution;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Çözümü Doğrula'),
      ),
      body: report == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: StatusBadge(label: report.status.label(null), tone: report.status.tone, icon: report.status.icon),
                ),
                const SizedBox(height: 12),
                Text('Çözümü Doğrulayın', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.navy, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text(
                  'Saha ekibi sorunun çözüldüğünü bildirdi. Lütfen sonucu kontrol edip geri bildirimde bulunun.',
                  style: TextStyle(color: AppColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _Tile(label: 'Önce', color: AppColors.navy, photo: report.photos.isEmpty ? const ReportPhoto() : report.photos.first)),
                    const SizedBox(width: 12),
                    const Expanded(child: _Tile(label: 'Sonra', color: AppColors.warning, photo: ReportPhoto())),
                  ],
                ),
                if (res != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.engineering_outlined, size: 18, color: AppColors.navy),
                            const SizedBox(width: 6),
                            const Expanded(child: Text('Ekibin Notu', style: TextStyle(fontWeight: FontWeight.w700))),
                            Text(formatLong(res.completedAt), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('“${res.note}”', style: const TextStyle(fontSize: 16, height: 1.4)),
                        const SizedBox(height: 8),
                        Text(res.team, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                const Text('Sonuç Değerlendirmesi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                _Option(
                  icon: Icons.check_circle_outline,
                  title: 'Çözüldü',
                  subtitle: 'Sorun giderildi, bildirim kapatılabilir',
                  tone: Tone.success,
                  selected: _resolved == true,
                  onTap: () => setState(() => _resolved = true),
                ),
                const SizedBox(height: 12),
                _Option(
                  icon: Icons.error_outline,
                  title: 'Hâlâ devam ediyor',
                  subtitle: 'Sorun giderilmedi, ihbar yeniden açılsın',
                  tone: Tone.danger,
                  selected: _resolved == false,
                  onTap: () => setState(() => _resolved = false),
                ),
                const SizedBox(height: 20),
                const FieldLabel('Yorum', optional: true),
                TextField(
                  controller: _comment,
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: 'Neyin eksik kaldığını yazabilirsiniz.'),
                ),
                if (_resolved == false)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Bu seçimle ihbar yeniden açılır ve kurum bilgilendirilir.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ),
              ],
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.border))),
        child: SafeArea(
          top: false,
          child: FilledButton(
            onPressed: (_resolved == null || _busy) ? null : _submit,
            child: _busy
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('Doğrulamayı Gönder'), SizedBox(width: 8), Icon(Icons.send_outlined, size: 18)]),
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.color, required this.photo});

  final String label;
  final Color color;
  final ReportPhoto photo;

  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: 3 / 4,
        child: Stack(
          children: [
            Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(12), child: ReportPhotoView(photo))),
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ),
          ],
        ),
      );
}

class _Option extends StatelessWidget {
  const _Option({required this.icon, required this.title, required this.subtitle, required this.tone, required this.selected, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final Tone tone;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppColors.navy : AppColors.border, width: selected ? 2 : 1),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: selected ? tone.bg : AppColors.neutralBg, shape: BoxShape.circle),
                child: Icon(icon, color: selected ? tone.fg : AppColors.textSecondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: selected ? AppColors.navy : AppColors.border),
            ],
          ),
        ),
      ),
    );
  }
}
