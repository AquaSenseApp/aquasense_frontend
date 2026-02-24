/// Category of an alert — controls the left accent colour and filter tab.
enum AlertType {
  alert,
  recommendation,
  anomaly,
  compliance;

  String get label {
    switch (this) {
      case AlertType.alert:          return 'Alert';
      case AlertType.recommendation: return 'Recommendation';
      case AlertType.anomaly:        return 'AI Anomaly';
      case AlertType.compliance:     return 'Compliance';
    }
  }
}

/// A single alert entry — can originate from the API or local mock data.
///
/// [apiId] is the backend integer ID; null for locally-seeded mock entries.
/// [status] is "active" | "resolved" — drives the resolve button visibility.
class AlertModel {
  /// Local string ID (used as widget key and list key).
  final String    id;

  /// Server-assigned integer ID — used for PATCH /api/alerts/resolve/{id}.
  final int?      apiId;

  final String    title;
  final String    description;

  /// Sensor reading snapshot shown beneath the description, e.g. "4.8 pH".
  final String    reading;

  /// Safe operating range, e.g. "6.5 – 6.8".
  final String    safeRange;

  final AlertType type;

  /// "active" | "resolved" — mirrors the backend status field.
  final String    status;

  final DateTime  timestamp;

  const AlertModel({
    required this.id,
    this.apiId,
    required this.title,
    required this.description,
    required this.reading,
    required this.safeRange,
    required this.type,
    this.status    = 'active',
    required this.timestamp,
  });

  /// One-line reading + safe range shown beneath the description.
  String get readingLine =>
      (reading.isEmpty && safeRange.isEmpty)
          ? description
          : '$reading | Safe: $safeRange';

  bool get isActive   => status == 'active';
  bool get isResolved => status == 'resolved';

  AlertModel copyWith({String? status}) => AlertModel(
    id:          id,
    apiId:       apiId,
    title:       title,
    description: description,
    reading:     reading,
    safeRange:   safeRange,
    type:        type,
    status:      status ?? this.status,
    timestamp:   timestamp,
  );
}

/// Filter state for the Alerts screen tab bar.
enum AlertFilter {
  all,
  alerts,
  recommendation;

  String get label {
    switch (this) {
      case AlertFilter.all:            return 'All';
      case AlertFilter.alerts:         return 'Alerts';
      case AlertFilter.recommendation: return 'Recommendation';
    }
  }

  /// Returns true if [type] should be visible under this filter.
  bool matches(AlertType type) {
    switch (this) {
      case AlertFilter.all:
        return true;
      case AlertFilter.alerts:
        return type == AlertType.alert ||
            type == AlertType.anomaly ||
            type == AlertType.compliance;
      case AlertFilter.recommendation:
        return type == AlertType.recommendation;
    }
  }
}
