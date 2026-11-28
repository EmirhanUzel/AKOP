import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../domain/new_report.dart';

const maxPhotos = 5;

/// Ankara merkez; konum izni yoksa harita buradan açılır (ihbar konumu olarak kaydedilmez).
const defaultLocation = LatLng(39.9032, 32.8597);

class ReportDraft {
  const ReportDraft({
    this.photos = const [],
    this.location,
    this.description = '',
    this.title = '',
    this.categoryCode,
    this.subcategoryCode,
    this.categoryAuto = false,
    this.locationDescription = '',
    this.answers = const {},
  });

  final List<String> photos;
  final LatLng? location;
  final String description;
  final String title;
  final String? categoryCode;
  final String? subcategoryCode;

  /// Kategori fotoğraf önerisinden otomatik seçildi; kullanıcı dokunana kadar fotoğraf değişince yenilenir.
  final bool categoryAuto;
  final String locationDescription;

  /// Dinamik form cevapları (soru kodu → seçenek kodu); yalnızca seçili kategorinin soruları.
  final Map<String, String> answers;

  ReportDraft copyWith({
    List<String>? photos,
    LatLng? location,
    String? description,
    String? title,
    String? categoryCode,
    String? subcategoryCode,
    String? locationDescription,
    Map<String, String>? answers,
    bool clearCategory = false,
    bool clearSubcategory = false,
    bool? categoryAuto,
  }) =>
      ReportDraft(
        photos: photos ?? this.photos,
        location: location ?? this.location,
        description: description ?? this.description,
        title: title ?? this.title,
        categoryCode: clearCategory ? null : (categoryCode ?? this.categoryCode),
        subcategoryCode: clearCategory || clearSubcategory ? null : (subcategoryCode ?? this.subcategoryCode),
        categoryAuto: clearCategory ? false : (categoryAuto ?? this.categoryAuto),
        locationDescription: locationDescription ?? this.locationDescription,
        answers: clearCategory ? const {} : (answers ?? this.answers),
      );

  /// Konum seçilmeden çağrılmaz: Konum adımı seçilmeden "Devam"ı kapalı tutar.
  NewReport toNewReport() {
    final loc = location!;
    return NewReport(
      photos: photos,
      lat: loc.latitude,
      lng: loc.longitude,
      description: description.trim(),
      title: title.trim().isEmpty ? null : title.trim(),
      categoryCode: categoryCode,
      subcategoryCode: subcategoryCode,
      locationDescription: locationDescription.trim().isEmpty ? null : locationDescription.trim(),
      answers: answers,
    );
  }
}

class DraftController extends Notifier<ReportDraft> {
  @override
  ReportDraft build() => const ReportDraft();

  void addPhotos(Iterable<String> paths) {
    final all = [...state.photos, ...paths];
    state = state.copyWith(photos: all.take(maxPhotos).toList());
  }

  void removePhoto(int index) {
    final all = [...state.photos]..removeAt(index);
    // Fotoğraf kalmadıysa ondan önerilen kategori de geçersiz
    state = state.copyWith(photos: all, clearCategory: all.isEmpty && state.categoryAuto);
  }

  void setLocation(LatLng l) => state = state.copyWith(location: l);

  void setDescription(String v) => state = state.copyWith(description: v);

  void setTitle(String v) => state = state.copyWith(title: v);

  void setLocationDescription(String v) => state = state.copyWith(locationDescription: v);

  /// Alt kategori ve cevaplar başka kategoriye ait olamaz (sunucu 400 verir): kategori değişince temizlenir.
  /// [auto]: fotoğraf önerisinden seçildi. Kullanıcının seçtiği kategori öneriyle değiştirilmez.
  void setCategory(String? code, {bool auto = false}) {
    if (code == state.categoryCode) {
      if (!auto) state = state.copyWith(categoryAuto: false);
      return;
    }
    state = code == null
        ? state.copyWith(clearCategory: true)
        : state.copyWith(categoryCode: code, clearSubcategory: true, categoryAuto: auto, answers: const {});
  }

  /// [option] null ise soru cevapsız kalır (sorular isteğe bağlı).
  /// Soruyu cevaplamak kategoriyi onaylamaktır: fotoğraf değişince öneri kategoriyi (ve cevapları) değiştirmez.
  void setAnswer(String question, String? option) {
    final answers = {...state.answers}..remove(question);
    if (option != null) answers[question] = option;
    state = state.copyWith(answers: answers, categoryAuto: false);
  }

  void setSubcategory(String? code) => state = code == null
      ? state.copyWith(clearSubcategory: true)
      : state.copyWith(subcategoryCode: code, categoryAuto: false);

  void reset() => state = const ReportDraft();
}

final draftProvider = NotifierProvider<DraftController, ReportDraft>(DraftController.new);
