import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../application/draft_controller.dart';
import '../report_map.dart';
import 'step_scaffold.dart';

/// C-05 İhbar 2/4: Konum. İğne ortada sabit, harita kaydırılır.
class LocationStep extends ConsumerStatefulWidget {
  const LocationStep({super.key});

  @override
  ConsumerState<LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends ConsumerState<LocationStep> {
  final _map = MapController();
  bool _denied = false;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final draft = ref.read(draftProvider);
      if (draft.location == null) _locate();
    });
  }

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    setState(() => _locating = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever || !await Geolocator.isLocationServiceEnabled()) {
        if (mounted) setState(() => _denied = true);
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      final p = LatLng(pos.latitude, pos.longitude);
      ref.read(draftProvider.notifier).setLocation(p);
      _map.move(p, 17);
      if (mounted) setState(() => _denied = false);
    } catch (_) {
      if (mounted) setState(() => _denied = true);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final picked = ref.watch(draftProvider.select((d) => d.location));
    final loc = picked ?? defaultLocation;
    return StepScaffold(
      step: 2,
      label: 'Konum',
      buttonLabel: 'Devam',
      hint: picked == null ? 'Konumunuzu alın ya da haritayı kaydırarak seçin.' : null,
      onNext: picked == null ? null : () => context.push('/yeni/detay'),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _map,
                  options: MapOptions(
                    initialCenter: loc,
                    initialZoom: 16,
                    onPositionChanged: (camera, hasGesture) {
                      if (hasGesture) ref.read(draftProvider.notifier).setLocation(camera.center);
                    },
                  ),
                  children: [osmTileLayer(), osmAttribution()],
                ),
                const IgnorePointer(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 44),
                      child: Icon(Icons.location_on, color: AppColors.navy, size: 48),
                    ),
                  ),
                ),
                if (_denied)
                  Positioned(
                    top: 12,
                    left: 16,
                    right: 72,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.warning)),
                      child: const Text(
                        'Konum izni verilmedi. Haritadan konumu elle seçebilirsiniz.',
                        style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ),
                Positioned(
                  top: 12,
                  right: 16,
                  child: Material(
                    color: AppColors.surface,
                    elevation: 2,
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: 'Konumumu kullan',
                      onPressed: _locating ? null : _locate,
                      icon: const Icon(Icons.my_location, color: AppColors.navy),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: const BoxDecoration(color: AppColors.surface),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SEÇİLEN KONUM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 20),
                    const SizedBox(width: 8),
                    Text(picked == null ? 'Henüz seçilmedi' : '${loc.latitude.toStringAsFixed(5)}, ${loc.longitude.toStringAsFixed(5)}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Haritayı kaydırarak konumu düzeltebilirsiniz.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _locating ? null : _locate,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: AppColors.navy,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.gps_fixed, size: 18),
                  label: const Text('Konumumu kullan'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
