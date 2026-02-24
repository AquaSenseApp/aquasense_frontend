import '../core/errors/api_exception.dart';
import '../core/network/api_endpoints.dart';
import '../core/network/dio_client.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DTOs
// ─────────────────────────────────────────────────────────────────────────────

/// Request body for POST /api/readings/upload.
class ReadingUploadRequest {
  final String apiKey;
  final double ph;
  final double temperature;
  final double turbidity;
  final double tds;
  final double dissolvedOxygen;

  const ReadingUploadRequest({
    required this.apiKey,
    required this.ph,
    required this.temperature,
    required this.turbidity,
    required this.tds,
    required this.dissolvedOxygen,
  });

  Map<String, dynamic> toJson() => {
    'api_key':          apiKey,
    'ph':               ph,
    'temperature':      temperature,
    'turbidity':        turbidity,
    'tds':              tds,
    'dissolved_oxygen': dissolvedOxygen,
  };
}

/// One analysed reading returned by the backend, e.g. pH or Turbidity.
class AnalysedReading {
  final String parameter; // "PH", "Turbidity", "Dissolved_Oxygen"
  final double value;
  final String result;    // human-readable advisory string from backend

  const AnalysedReading({
    required this.parameter,
    required this.value,
    required this.result,
  });
}

/// Full response from POST /api/readings/upload.
class ReadingUploadResponse {
  final String               message;
  final List<AnalysedReading> readings;

  const ReadingUploadResponse({
    required this.message,
    required this.readings,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────

class ReadingService {
  ReadingService._();
  static final ReadingService instance = ReadingService._();

  final _dio = DioClient.instance;

  /// POST /api/readings/upload
  ///
  /// Uploads sensor readings and returns the backend's analysis result.
  Future<ReadingUploadResponse> upload(ReadingUploadRequest req) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.uploadReading,
        data: req.toJson(),
      );
      final data = res.data!;

      // Parse each known parameter block — the backend may omit some
      final readings = <AnalysedReading>[];
      const keys = ['PH', 'Turbidity', 'Dissolved_Oxygen', 'Temperature', 'TDS'];
      for (final key in keys) {
        final block = data[key] as Map<String, dynamic>?;
        if (block != null) {
          readings.add(AnalysedReading(
            parameter: key,
            value:     (block['value'] as num).toDouble(),
            result:    block['result'] as String,
          ));
        }
      }

      return ReadingUploadResponse(
        message:  data['message'] as String? ?? 'Data recorded',
        readings: readings,
      );
    } catch (e) {
      throw extractApiException(e);
    }
  }
}
