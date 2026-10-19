import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/report.dart';

class ReportPhotoView extends StatelessWidget {
  const ReportPhotoView(this.photo, {super.key, this.fit = BoxFit.cover});

  final ReportPhoto photo;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final path = photo.path;
    if (path != null) return Image.file(File(path), fit: fit, errorBuilder: (_, _, _) => const _Placeholder());
    return const _Placeholder();
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) => const ColoredBox(
        color: AppColors.neutralBg,
        child: Center(child: Icon(Icons.image_outlined, color: AppColors.textSecondary)),
      );
}
