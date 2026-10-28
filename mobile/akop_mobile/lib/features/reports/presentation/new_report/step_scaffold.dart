import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';

/// C-04..C-07 ortak iskeleti: üst çubuk, 4 adımlı ilerleme, sabit alt düğme.
class StepScaffold extends StatelessWidget {
  const StepScaffold({
    super.key,
    required this.step,
    required this.label,
    required this.child,
    required this.buttonLabel,
    required this.onNext,
    this.buttonIcon = Icons.arrow_forward,
    this.busy = false,
    this.firstStep = false,
    this.hint,
  });

  final int step;
  final String label;
  final Widget child;
  final String buttonLabel;
  final VoidCallback? onNext;
  final IconData buttonIcon;
  final bool busy;
  final bool firstStep;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          tooltip: firstStep ? 'Kapat' : 'Geri',
          icon: Icon(firstStep ? Icons.close : Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Yeni İhbar'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.orange, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('$step/4 $label', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const Spacer(),
                    Text('Adım $step / 4', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (var i = 1; i <= 4; i++) ...[
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: i <= step ? AppColors.navy : AppColors.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      if (i < 4) const SizedBox(width: 6),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Expanded(child: child),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.border))),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hint != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(hint!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ),
                  FilledButton(
                    onPressed: busy ? null : onNext,
                    child: busy
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [Text(buttonLabel), const SizedBox(width: 8), Icon(buttonIcon, size: 20)],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
