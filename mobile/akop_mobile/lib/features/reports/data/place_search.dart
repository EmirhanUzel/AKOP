import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

class Place {
  const Place(this.name, this.point);
  final String name;
  final LatLng point;
}

/// Adres/yer araması: OpenStreetMap Nominatim, Türkiye ile sınırlı.
/// Kendi Dio'su var: uygulamanın token ekleyen Dio'su dış servise gitmemeli.
/// shortcut: ücretsiz Nominatim saniyede 1 istek sınırlı (yalnızca gönderince aranır), gerçek kullanımda kendi sunucumuz ya da ücretli servis.
class PlaceSearch {
  PlaceSearch([Dio? dio]) : _dio = dio ?? Dio(BaseOptions(headers: {'User-Agent': 'AKOP-mobile'}));

  final Dio _dio;

  Future<List<Place>> search(String query) async {
    final res = await _dio.get<dynamic>('https://nominatim.openstreetmap.org/search', queryParameters: {
      'q': query,
      'format': 'jsonv2',
      'limit': 5,
      'countrycodes': 'tr',
      'accept-language': 'tr',
    });
    final data = res.data;
    if (data is! List) return const [];
    return [
      for (final p in data.whereType<Map<String, dynamic>>())
        if (double.tryParse('${p['lat']}') case final lat?)
          if (double.tryParse('${p['lon']}') case final lon?) Place(p['display_name'] as String? ?? '', LatLng(lat, lon)),
    ];
  }
}

final placeSearchProvider = Provider<PlaceSearch>((_) => PlaceSearch());
