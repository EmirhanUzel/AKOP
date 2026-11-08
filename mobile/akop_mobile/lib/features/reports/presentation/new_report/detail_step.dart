import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../application/draft_controller.dart';
import '../../domain/report_category.dart';
import 'step_scaffold.dart';

/// C-06 İhbar 3/4: Detay
class DetailStep extends ConsumerStatefulWidget {
  const DetailStep({super.key});

  @override
  ConsumerState<DetailStep> createState() => _DetailStepState();
}

class _DetailStepState extends ConsumerState<DetailStep> {
  final _formKey = GlobalKey<FormState>();
  late final _description = TextEditingController(text: ref.read(draftProvider).description);
  late final _title = TextEditingController(text: ref.read(draftProvider).title);
  late final _place = TextEditingController(text: ref.read(draftProvider).locationDescription);

  @override
  void dispose() {
    _description.dispose();
    _title.dispose();
    _place.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.read(draftProvider.notifier);
    final category = ref.watch(draftProvider.select((d) => d.categoryCode));
    return StepScaffold(
      step: 3,
      label: 'Detay',
      buttonLabel: 'Devam',
      onNext: () {
        if (_formKey.currentState!.validate()) context.push('/yeni/ozet');
      },
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          children: [
            const FieldLabel('Açıklama', required: true),
            TextFormField(
              controller: _description,
              maxLines: 6,
              minLines: 5,
              maxLength: 2000,
              textCapitalization: TextCapitalization.sentences,
              onChanged: draft.setDescription,
              decoration: const InputDecoration(hintText: 'Sorunu kısaca anlatın…', counterText: ''),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Açıklama zorunludur.' : null,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _description,
                builder: (_, v, _) => Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Olayın yeri, ne zaman başladığı ve olası riskleri belirtmeniz çözümü hızlandırır.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${v.text.length} / 2000', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const FieldLabel('Başlık', optional: true),
            TextFormField(
              controller: _title,
              maxLength: 120,
              onChanged: draft.setTitle,
              decoration: const InputDecoration(hintText: 'Örn. Kaldırım taşları kırık'),
            ),
            const SizedBox(height: 8),
            const FieldLabel('Adres tarifi', optional: true),
            TextFormField(
              controller: _place,
              maxLength: 300,
              onChanged: draft.setLocationDescription,
              decoration: const InputDecoration(hintText: 'Örn. Okul girişinin karşısı'),
            ),
            const SizedBox(height: 8),
            const FieldLabel('Kategori', optional: true),
            DropdownButtonFormField<String>(
              initialValue: category,
              isExpanded: true,
              hint: const Text('Kategori seçin'),
              decoration: const InputDecoration(),
              items: [
                for (final c in reportCategories)
                  DropdownMenuItem(
                    value: c.code,
                    child: Row(children: [Icon(c.icon, size: 20, color: AppColors.navy), const SizedBox(width: 12), Text(c.name)]),
                  ),
              ],
              onChanged: draft.setCategory,
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.auto_awesome, size: 16, color: AppColors.orange),
                SizedBox(width: 6),
                Text('Boş bırakırsanız sistem sizin için önerir.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
