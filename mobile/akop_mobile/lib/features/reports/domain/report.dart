import 'package:flutter/material.dart';

import '../../../core/widgets/status_badge.dart';

enum ReportStatus {
  submitted,
  awaitingInstitution,
  needsCitizenInfo,
  unroutable,
  accepted,
  inProgress,
  resolvedPendingConfirmation,
  reopened,
  closed,
}

extension ReportStatusX on ReportStatus {
  String label(String? org) => switch (this) {
        ReportStatus.submitted => 'Alındı, inceleniyor',
        ReportStatus.awaitingInstitution => 'Kurumlara iletildi',
        ReportStatus.needsCitizenInfo => 'Ek bilgi gerekli',
        ReportStatus.unroutable => 'Yönlendirme sürüyor',
        ReportStatus.accepted => org == null ? 'Kurum üstlendi' : '$org üstlendi',
        ReportStatus.inProgress => 'Çalışma sürüyor',
        ReportStatus.resolvedPendingConfirmation => 'Onayınız bekleniyor',
        ReportStatus.reopened => 'Yeniden açıldı',
        ReportStatus.closed => 'Çözüldü',
      };

  Tone get tone => switch (this) {
        ReportStatus.submitted || ReportStatus.unroutable => Tone.neutral,
        ReportStatus.awaitingInstitution || ReportStatus.accepted || ReportStatus.inProgress => Tone.info,
        ReportStatus.needsCitizenInfo || ReportStatus.resolvedPendingConfirmation => Tone.warning,
        ReportStatus.reopened => Tone.danger,
        ReportStatus.closed => Tone.success,
      };

  IconData get icon => switch (this) {
        ReportStatus.submitted => Icons.inbox_outlined,
        ReportStatus.awaitingInstitution => Icons.send_outlined,
        ReportStatus.needsCitizenInfo => Icons.info_outline,
        ReportStatus.unroutable => Icons.hourglass_empty,
        ReportStatus.accepted => Icons.account_balance_outlined,
        ReportStatus.inProgress => Icons.engineering_outlined,
        ReportStatus.resolvedPendingConfirmation => Icons.assignment_turned_in_outlined,
        ReportStatus.reopened => Icons.replay,
        ReportStatus.closed => Icons.check_circle_outline,
      };

  String get nextStep => switch (this) {
        ReportStatus.submitted => 'İhbarınız alındı, inceleniyor.',
        ReportStatus.awaitingInstitution => 'İhbarınız ilgili kurumlara iletildi.',
        ReportStatus.needsCitizenInfo => 'Doğru kuruma ulaşmak için ek bilgiye ihtiyaç var.',
        ReportStatus.unroutable => 'Uygun kurum aranıyor.',
        ReportStatus.accepted => 'Kurum ihbarı üstlendi, ekip atanması bekleniyor.',
        ReportStatus.inProgress => 'Saha ekibi sorun üzerinde çalışıyor.',
        ReportStatus.resolvedPendingConfirmation => 'Çözüm tamamlandı. Lütfen sonucu onaylayın.',
        ReportStatus.reopened => 'İhbar yeniden açıldı, kurum bilgilendirildi.',
        ReportStatus.closed => 'Bu ihbar kapatıldı.',
      };
}

enum ReportFilter {
  all('Tümü'),
  ongoing('Devam eden'),
  awaitingConfirmation('Onay bekleyen'),
  resolved('Çözülen');

  const ReportFilter(this.label);
  final String label;

  bool matches(ReportStatus s) => switch (this) {
        ReportFilter.all => true,
        ReportFilter.ongoing => s != ReportStatus.resolvedPendingConfirmation && s != ReportStatus.closed,
        ReportFilter.awaitingConfirmation => s == ReportStatus.resolvedPendingConfirmation,
        ReportFilter.resolved => s == ReportStatus.closed,
      };
}

/// [path] null ise yer tutucu gösterilir (sahte veri).
class ReportPhoto {
  const ReportPhoto([this.path]);
  final String? path;
}

class TimelineEntry {
  const TimelineEntry(this.label, this.at);
  final String label;
  final DateTime at;
}

class Resolution {
  const Resolution({required this.note, required this.team, required this.completedAt});
  final String note;
  final String team;
  final DateTime completedAt;
}

class Report {
  const Report({
    required this.id,
    required this.title,
    required this.description,
    required this.lat,
    required this.lng,
    required this.status,
    required this.createdAt,
    required this.photos,
    required this.timeline,
    this.categoryCode,
    this.organization,
    this.locationText,
    this.resolution,
  });

  final String id;
  final String title;
  final String description;
  final double lat;
  final double lng;
  final String? categoryCode;
  final String? organization;
  final String? locationText;
  final ReportStatus status;
  final DateTime createdAt;
  final List<ReportPhoto> photos;
  final List<TimelineEntry> timeline;
  final Resolution? resolution;

  String get locationLabel => locationText ?? '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';

  Report copyWith({ReportStatus? status, List<TimelineEntry>? timeline}) => Report(
        id: id,
        title: title,
        description: description,
        lat: lat,
        lng: lng,
        status: status ?? this.status,
        createdAt: createdAt,
        photos: photos,
        timeline: timeline ?? this.timeline,
        categoryCode: categoryCode,
        organization: organization,
        locationText: locationText,
        resolution: resolution,
      );
}

/// C-04..C-07 akışının topladığı veri.
class NewReport {
  const NewReport({
    required this.photos,
    required this.lat,
    required this.lng,
    required this.description,
    this.title,
    this.categoryCode,
  });

  final List<String> photos;
  final double lat;
  final double lng;
  final String description;
  final String? title;
  final String? categoryCode;
}
