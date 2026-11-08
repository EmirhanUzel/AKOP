import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../domain/new_report.dart';

const maxPhotos = 5;

/// Ankara merkez; konum izni yoksa harita buradan açılır.
const defaultLocation = LatLng(39.9032, 32.8597);

class ReportDraft {
  const ReportDraft({
    this.photos = const [],
    this.location,
    this.description = '',
    this.title = '',
    this.categoryCode,
    this.locationDescription = '',
  });

  final List<String> photos;
  final LatLng? location;
  final String description;
  final String title;
  final String? categoryCode;
  final String locationDescription;

  ReportDraft copyWith({
    List<String>? photos,
    LatLng? location,
    String? description,
    String? title,
    String? categoryCode,
    String? locationDescription,
    bool clearCategory = false,
  }) =>
      ReportDraft(
        photos: photos ?? this.photos,
        location: location ?? this.location,
        description: description ?? this.description,
        title: title ?? this.title,
        categoryCode: clearCategory ? null : (categoryCode ?? this.categoryCode),
        locationDescription: locationDescription ?? this.locationDescription,
      );

  NewReport toNewReport() {
    final loc = location ?? defaultLocation;
    return NewReport(
      photos: photos,
      lat: loc.latitude,
      lng: loc.longitude,
      description: description.trim(),
      title: title.trim().isEmpty ? null : title.trim(),
      categoryCode: categoryCode,
      locationDescription: locationDescription.trim().isEmpty ? null : locationDescription.trim(),
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
    state = state.copyWith(photos: all);
  }

  void setLocation(LatLng l) => state = state.copyWith(location: l);

  void setDescription(String v) => state = state.copyWith(description: v);

  void setTitle(String v) => state = state.copyWith(title: v);

  void setLocationDescription(String v) => state = state.copyWith(locationDescription: v);

  void setCategory(String? code) =>
      state = code == null ? state.copyWith(clearCategory: true) : state.copyWith(categoryCode: code);

  void reset() => state = const ReportDraft();
}

final draftProvider = NotifierProvider<DraftController, ReportDraft>(DraftController.new);
