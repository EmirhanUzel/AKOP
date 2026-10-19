import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum Tone { info, success, warning, danger, neutral }

extension ToneColors on Tone {
  Color get fg => switch (this) {
        Tone.info => AppColors.info,
        Tone.success => AppColors.success,
        Tone.warning => AppColors.warning,
        Tone.danger => AppColors.danger,
        Tone.neutral => AppColors.neutral,
      };

  Color get bg => switch (this) {
        Tone.info => AppColors.infoBg,
        Tone.success => AppColors.successBg,
        Tone.warning => AppColors.warningBg,
        Tone.danger => AppColors.dangerBg,
        Tone.neutral => AppColors.neutralBg,
      };
}

/// Durum rozeti: renk + ikon + metin (durum asla yalnız renkle verilmez).
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.tone, required this.icon});

  final String label;
  final Tone tone;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 24),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: tone.bg, borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: tone.fg),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(color: tone.fg, fontSize: 12, fontWeight: FontWeight.w600, height: 1.2),
            ),
          ),
        ],
      ),
    );
  }
}
