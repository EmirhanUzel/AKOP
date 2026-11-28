/// C-04..C-07 akışının topladığı veri.
class NewReport {
  const NewReport({
    required this.photos,
    required this.lat,
    required this.lng,
    required this.description,
    this.title,
    this.categoryCode,
    this.subcategoryCode,
    this.locationDescription,
    this.answers = const {},
  });

  final List<String> photos;
  final double lat;
  final double lng;
  final String description;
  final String? title;
  final String? categoryCode;
  final String? subcategoryCode;
  final String? locationDescription;

  /// Dinamik form cevapları: soru kodu → seçenek kodu.
  final Map<String, String> answers;
}
