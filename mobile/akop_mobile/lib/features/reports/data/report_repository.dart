import '../domain/report.dart';

abstract interface class ReportRepository {
  Future<List<Report>> list();
  Future<Report> create(NewReport report);
  Future<Report> confirm(String id, {required bool resolved, String? comment});
  Future<Report> provideInfo(String id, {String? text, List<String> photos = const []});
}

/// API hazır olana kadar bellekte çalışır.
class FakeReportRepository implements ReportRepository {
  FakeReportRepository({this.delay = const Duration(milliseconds: 400)}) : _items = _seed();

  final Duration delay;
  final List<Report> _items;
  int _next = 100;

  Future<void> _wait() => Future<void>.delayed(delay);

  @override
  Future<List<Report>> list() async {
    await _wait();
    return List.of(_items);
  }

  @override
  Future<Report> create(NewReport n) async {
    await _wait();
    final now = DateTime.now();
    final r = Report(
      id: '${_next++}',
      title: (n.title == null || n.title!.trim().isEmpty) ? _firstLine(n.description) : n.title!.trim(),
      description: n.description,
      lat: n.lat,
      lng: n.lng,
      categoryCode: n.categoryCode,
      status: ReportStatus.submitted,
      createdAt: now,
      photos: [for (final p in n.photos) ReportPhoto(p)],
      timeline: [TimelineEntry('İhbar alındı', now)],
    );
    _items.insert(0, r);
    return r;
  }

  @override
  Future<Report> confirm(String id, {required bool resolved, String? comment}) async {
    await _wait();
    final now = DateTime.now();
    return _update(
      id,
      resolved ? ReportStatus.closed : ReportStatus.reopened,
      resolved ? 'Çözüm doğrulandı' : 'Vatandaş: sorun sürüyor',
      now,
    );
  }

  @override
  Future<Report> provideInfo(String id, {String? text, List<String> photos = const []}) async {
    await _wait();
    return _update(id, ReportStatus.submitted, 'Ek bilgi iletildi', DateTime.now());
  }

  Report _update(String id, ReportStatus status, String entry, DateTime at) {
    final i = _items.indexWhere((r) => r.id == id);
    final old = _items[i];
    final updated = old.copyWith(status: status, timeline: [...old.timeline, TimelineEntry(entry, at)]);
    _items[i] = updated;
    return updated;
  }

  static String _firstLine(String s) {
    final t = s.trim().split('\n').first;
    return t.length > 60 ? '${t.substring(0, 57)}…' : t;
  }
}

List<Report> _seed() {
  DateTime d(int day, int h, int m) => DateTime(2026, 10, day, h, m);
  const photos3 = [ReportPhoto(), ReportPhoto(), ReportPhoto()];
  final ankara = Resolution(
    note: 'Çukur asfaltla kapatıldı, çevre temizliği tamamlandı.',
    team: 'Çankaya Belediyesi, Yol Bakım Ekibi 1',
    completedAt: DateTime(2026, 10, 15, 13, 5),
  );
  return [
    Report(
      id: '1',
      title: 'Sokağın ortasında derin çukur',
      description:
          'Asfalt yolun ortasında araçların geçişini engelleyen ve kaza riski oluşturan yaklaşık 40 cm genişliğinde çukur bulunmaktadır.',
      lat: 39.9032,
      lng: 32.8597,
      locationText: 'Çayyolu Mah. 2432. Cadde',
      categoryCode: 'ROAD_DAMAGE',
      organization: 'Çankaya Belediyesi',
      status: ReportStatus.inProgress,
      createdAt: d(14, 9, 12),
      photos: photos3,
      timeline: [
        TimelineEntry('İhbar alındı', d(14, 9, 12)),
        TimelineEntry('Kurumlara iletildi', d(14, 9, 13)),
        TimelineEntry('Çankaya Belediyesi üstlendi', d(14, 9, 20)),
        TimelineEntry('Ekip atandı', d(14, 9, 31)),
        TimelineEntry('Çalışma sürüyor', d(15, 8, 40)),
      ],
    ),
    Report(
      id: '2',
      title: 'Çöp konteyneri taşmış',
      description: 'Konteyner taşmış, çevreye çöp dökülmüş.',
      lat: 39.9086,
      lng: 32.8541,
      locationText: 'Tunalı Hilmi Cad. No:68',
      categoryCode: 'WASTE',
      organization: 'Çankaya Belediyesi',
      status: ReportStatus.accepted,
      createdAt: d(13, 17, 45),
      photos: const [ReportPhoto(), ReportPhoto()],
      timeline: [
        TimelineEntry('İhbar alındı', d(13, 17, 45)),
        TimelineEntry('Kurumlara iletildi', d(13, 17, 46)),
        TimelineEntry('Çankaya Belediyesi üstlendi', d(13, 18, 2)),
      ],
    ),
    Report(
      id: '3',
      title: 'Sokak lambası yanmıyor',
      description: 'Güvenlik Sokak girişindeki lamba birkaç gündür yanmıyor.',
      lat: 39.9002,
      lng: 32.8639,
      locationText: 'Ayrancı, Güvenlik Sokak',
      categoryCode: 'LIGHTING',
      organization: 'Çankaya Belediyesi',
      status: ReportStatus.resolvedPendingConfirmation,
      createdAt: d(12, 21, 3),
      photos: const [ReportPhoto(), ReportPhoto()],
      resolution: ankara,
      timeline: [
        TimelineEntry('İhbar alındı', d(12, 21, 3)),
        TimelineEntry('Kurumlara iletildi', d(12, 21, 4)),
        TimelineEntry('Çankaya Belediyesi üstlendi', d(13, 8, 30)),
        TimelineEntry('Ekip atandı', d(13, 9, 10)),
        TimelineEntry('Çözüm tamamlandı', d(15, 13, 5)),
      ],
    ),
    Report(
      id: '4',
      title: 'Su borusu patlak',
      description: 'Kaldırımda su sızıyor.',
      lat: 39.9101,
      lng: 32.8702,
      locationText: 'Kavaklıdere, Bestekar Sok.',
      categoryCode: 'WATER_LEAK',
      status: ReportStatus.needsCitizenInfo,
      createdAt: d(10, 11, 30),
      photos: const [ReportPhoto()],
      timeline: [
        TimelineEntry('İhbar alındı', d(10, 11, 30)),
        TimelineEntry('Ek bilgi istendi', d(10, 11, 45)),
      ],
    ),
    Report(
      id: '5',
      title: 'Kırık kaldırım taşı',
      description: 'Kaldırım taşları kırık, yürümek tehlikeli.',
      lat: 39.9055,
      lng: 32.8478,
      locationText: 'Emek Mah. 8. Cadde',
      categoryCode: 'SIDEWALK',
      organization: 'Çankaya Belediyesi',
      status: ReportStatus.closed,
      createdAt: d(8, 14, 20),
      photos: const [ReportPhoto(), ReportPhoto()],
      timeline: [
        TimelineEntry('İhbar alındı', d(8, 14, 20)),
        TimelineEntry('Kurumlara iletildi', d(8, 14, 21)),
        TimelineEntry('Çankaya Belediyesi üstlendi', d(8, 15, 0)),
        TimelineEntry('Çözüm doğrulandı', d(10, 9, 15)),
      ],
    ),
  ];
}
