enum ReportStatus {
  pending('Onay bekleyen'),
  inProgress('Devam eden'),
  resolved('Çözülen');

  const ReportStatus(this.label);

  final String label;
}

/// Vatandaşın oluşturduğu bir ihbar (liste ve kart için).
class Report {
  const Report({
    required this.id,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.locationText,
    this.categoryCode,
    this.description = '',
    this.imageUrls = const [],
  });

  final String id;
  final String title;
  final ReportStatus status;
  final DateTime createdAt;
  final String locationText;
  final String? categoryCode;
  final String description;

  /// Sunucudaki göreli fotoğraf adresleri; [ReportRepository.image] ile indirilir.
  final List<String> imageUrls;
}
