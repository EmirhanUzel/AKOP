import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';

TileLayer osmTileLayer() => TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.akop.akop_mobile',
    );

Widget osmAttribution() => const RichAttributionWidget(
      attributions: [TextSourceAttribution('© OpenStreetMap katkıda bulunanlar')],
    );

/// Merkezde sabit iğneli, dokunulamayan küçük harita.
class StaticReportMap extends StatelessWidget {
  const StaticReportMap({super.key, required this.center, this.height = 140});

  final LatLng center;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: 16,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
              ),
              children: [osmTileLayer(), osmAttribution()],
            ),
            const IgnorePointer(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 36),
                  child: Icon(Icons.location_on, color: AppColors.navy, size: 40),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
