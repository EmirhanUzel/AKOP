import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';

final _picker = ImagePicker();

/// Kameradan tek fotoğraf; iptal ya da hata olursa null.
Future<String?> pickFromCamera() async {
  try {
    final x = await _picker.pickImage(source: ImageSource.camera, maxWidth: 1920, imageQuality: 85);
    return x?.path;
  } catch (_) {
    return null;
  }
}

/// Galeriden en çok [limit] fotoğraf.
Future<List<String>> pickFromGallery(int limit) async {
  if (limit <= 0) return const [];
  try {
    final xs = await _picker.pickMultiImage(maxWidth: 1920, imageQuality: 85, limit: limit);
    return [for (final x in xs.take(limit)) x.path];
  } catch (_) {
    return const [];
  }
}

/// Küçük resim satırı: silme (x) düğmeli, isteğe bağlı "Ekle" kutulu.
class PhotoStrip extends StatelessWidget {
  const PhotoStrip({super.key, required this.photos, required this.onRemove, this.onAdd, this.size = 72});

  final List<String> photos;
  final void Function(int index) onRemove;
  final VoidCallback? onAdd;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size + 8,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < photos.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 8),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(File(photos[i]), width: size, height: size, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: -8,
                    right: -8,
                    child: InkResponse(
                      onTap: () => onRemove(i),
                      radius: 24,
                      child: Semantics(
                        label: 'Fotoğrafı kaldır',
                        button: true,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(color: AppColors.navy, shape: BoxShape.circle),
                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (onAdd != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: InkWell(
                onTap: onAdd,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: AppColors.textSecondary),
                      Text('Ekle', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
