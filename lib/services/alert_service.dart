import '../core/errors/api_exception.dart';
import '../core/network/api_endpoints.dart';
import '../core/network/dio_client.dart';
import '../models/alert_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DTO
// ─────────────────────────────────────────────────────────────────────────────

/// Raw alert shape from the backend.
/// Maps to [AlertModel] via [ApiAlertDto.toModel].
class ApiAlertDto {
  final int    id;
  final String message;
  final String status; // "active" | "resolved"
  final DateTime createdAt;
  final DateTime updatedAt;
  final int    readingId;

  const ApiAlertDto({
    required this.id,
    required this.message,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.readingId,
  });

  factory ApiAlertDto.fromJson(Map<String, dynamic> json) => ApiAlertDto(
    id:        json['id']        as int,
    message:   json['message']   as String,
    status:    json['status']    as String? ?? 'active',
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    readingId: json['ReadingId'] as int? ?? 0,
  );

  bool get isResolved => status == 'resolved';

  /// Converts to the UI [AlertModel] used by [AlertProvider] and [AlertsScreen].
  ///
  /// The backend message contains the full advisory text, so we extract a
  /// short title and longer description from it for display.
  AlertModel toModel() {
    // Extract a short title from the message prefix
    final title = _extractTitle(message);
    final description = _extractDescription(message);

    // Determine type from the message text
    final type = _inferType(message);

    return AlertModel(
      id:          id.toString(),
      apiId:       id,
      title:       title,
      description: description,
      reading:     '',   // populated from analytics if available
      safeRange:   '',
      type:        type,
      status:      status,
      timestamp:   createdAt,
    );
  }

  String _extractTitle(String msg) {
    // e.g. "Issue Detected: pH is 3, Turbidity is 4. Advisory: ..."
    // → "Issue Detected: pH is 3, Turbidity is 4"
    final dotIdx = msg.indexOf('.');
    if (dotIdx > 0 && dotIdx < 80) {
      return msg.substring(0, dotIdx).replaceFirst('Issue Detected: ', '').trim();
    }
    return msg.length > 60 ? '${msg.substring(0, 60)}…' : msg;
  }

  String _extractDescription(String msg) {
    // Return the Advisory part after the first period
    final dotIdx = msg.indexOf('Advisory:');
    if (dotIdx >= 0) return msg.substring(dotIdx);
    return msg;
  }

  AlertType _inferType(String msg) {
    final lower = msg.toLowerCase();
    if (lower.contains('recommend') || lower.contains('advisory')) {
      return AlertType.recommendation;
    }
    if (lower.contains('anomal')) return AlertType.anomaly;
    if (lower.contains('compli')) return AlertType.compliance;
    return AlertType.alert;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────

class AlertService {
  AlertService._();
  static final AlertService instance = AlertService._();

  final _dio = DioClient.instance;

  /// GET /api/alerts/user/{userId}
  Future<List<ApiAlertDto>> getAlertsForUser(int userId) async {
    try {
      final res = await _dio.get<List<dynamic>>(
        ApiEndpoints.alertsByUser(userId),
      );
      final list = res.data ?? [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(ApiAlertDto.fromJson)
          .toList();
    } catch (e) {
      throw extractApiException(e);
    }
  }

  /// PATCH /api/alerts/resolve/{alertId}
  ///
  /// Returns the resolved [ApiAlertDto].
  Future<ApiAlertDto> resolveAlert(int alertId) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.resolveAlert(alertId),
      );
      final data = res.data!;
      // Response: { "message": ..., "alert": { ... } }
      final alertJson = data['alert'] as Map<String, dynamic>? ?? data;
      return ApiAlertDto.fromJson(alertJson);
    } catch (e) {
      throw extractApiException(e);
    }
  }
}
