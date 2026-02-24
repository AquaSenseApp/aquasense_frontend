import '../core/errors/api_exception.dart';
import '../core/network/api_endpoints.dart';
import '../core/network/dio_client.dart';
import '../models/sensor_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Response DTO — returned after registering a sensor
// ─────────────────────────────────────────────────────────────────────────────

/// Data returned by POST /api/sensors/register.
class RegisteredSensor {
  final int    sensorId;
  final String apiKey;
  final String message;

  const RegisteredSensor({
    required this.sensorId,
    required this.apiKey,
    required this.message,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// API sensor model — raw shape returned by the backend list endpoint
// ─────────────────────────────────────────────────────────────────────────────

/// Lightweight DTO for a sensor record from GET /api/sensors/user/{userId}.
///
/// The backend returns minimal fields; the app's rich [SensorModel] is built
/// by [SensorProvider] which merges this with any local / AI data.
class ApiSensorDto {
  final int    id;
  final String name;
  final String type;
  final String location;
  final String apiKey;
  final int    userId;

  const ApiSensorDto({
    required this.id,
    required this.name,
    required this.type,
    required this.location,
    required this.apiKey,
    required this.userId,
  });

  factory ApiSensorDto.fromJson(Map<String, dynamic> json) => ApiSensorDto(
    id:       json['id']          as int,
    name:     (json['sensor_name'] ?? json['name'] ?? '') as String,
    type:     (json['sensor_type'] ?? json['type'] ?? '') as String,
    location: (json['location']   ?? '')                  as String,
    apiKey:   (json['apiKey']     ?? '')                  as String,
    userId:   (json['UserId']     ?? json['userId'] ?? 0) as int,
  );

  /// Map the backend sensor_type string to a [ParameterType] enum value.
  ParameterType get parameterType {
    final t = type.toLowerCase();
    if (t.contains('ph'))          return ParameterType.pH;
    if (t.contains('turbid'))      return ParameterType.turbidity;
    if (t.contains('oxygen'))      return ParameterType.dissolvedOxygen;
    if (t.contains('temp'))        return ParameterType.temperature;
    if (t.contains('conduct'))     return ParameterType.conductivity;
    return ParameterType.other;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────

class SensorService {
  SensorService._();
  static final SensorService instance = SensorService._();

  final _dio = DioClient.instance;

  // ── Register ────────────────────────────────────────────────────────────

  /// POST /api/sensors/register
  ///
  /// Body:     { sensor_name, sensor_type, location, UserId }
  /// Response: { message, sensorId, apiKey }
  Future<RegisteredSensor> registerSensor({
    required String sensorName,
    required String sensorType,
    required String location,
    required int    userId,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.registerSensor,
        data: {
          'sensor_name': sensorName,
          'sensor_type': sensorType,
          'location':    location,
          'UserId':      userId,
        },
      );
      final d = res.data!;
      return RegisteredSensor(
        sensorId: d['sensorId'] as int,
        apiKey:   d['apiKey']   as String,
        message:  d['message']  as String,
      );
    } catch (e) {
      throw extractApiException(e);
    }
  }

  // ── Fetch user sensors ──────────────────────────────────────────────────

  /// GET /api/sensors/user/{userId}
  ///
  /// Returns a list of [ApiSensorDto]s owned by the given user.
  Future<List<ApiSensorDto>> getSensorsForUser(int userId) async {
    try {
      final res = await _dio.get<List<dynamic>>(
        ApiEndpoints.sensorsByUser(userId),
      );
      final list = res.data ?? [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(ApiSensorDto.fromJson)
          .toList();
    } catch (e) {
      throw extractApiException(e);
    }
  }
}
