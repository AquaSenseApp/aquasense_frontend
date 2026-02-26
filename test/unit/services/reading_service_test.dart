// test/unit/services/reading_service_test.dart
//
// WHY these tests exist
// ─────────────────────
// ReadingUploadRequest.toJson() builds the exact JSON body sent to the
// backend.  The backend uses snake_case keys ("api_key", "dissolved_oxygen")
// while Dart uses camelCase internally.  A mismatch means every upload
// silently posts null values and the backend stores zeros — without ever
// returning an error the UI can show.
//
// AnalysedReading carries the backend's analysis result that the UI renders
// in the result card.  We test the DTO construction to ensure that the
// parameter name and value survive the JSON → Dart boundary correctly.
//
// We do NOT test the HTTP call itself here (that requires a real or mock
// server).  Those tests belong in the integration layer.

import 'package:flutter_test/flutter_test.dart';
import 'package:aquasense/services/reading_service.dart';
import '../../helpers/test_helpers.dart';

void main() {
  // ── ReadingUploadRequest.toJson() ─────────────────────────────────────────

  group('ReadingUploadRequest · toJson()', () {
    const request = ReadingUploadRequest(
      apiKey:          'AQ-2652f24e16131d085be59dea48fda0a7',
      ph:              3.0,
      temperature:     24.8,
      turbidity:       4.0,
      tds:             300.0,
      dissolvedOxygen: 7.2,
    );

    late Map<String, dynamic> json;

    setUp(() => json = request.toJson());

    test('serialises apiKey under the snake_case key "api_key"', () {
      expect(json['api_key'], 'AQ-2652f24e16131d085be59dea48fda0a7',
          reason: 'The backend expects "api_key", not "apiKey" — a wrong key '
              'causes a 401 / 400 because the sensor cannot be identified');
    });

    test('serialises ph under key "ph"', () {
      expect(json['ph'], 3.0);
    });

    test('serialises temperature under key "temperature"', () {
      expect(json['temperature'], 24.8);
    });

    test('serialises turbidity under key "turbidity"', () {
      expect(json['turbidity'], 4.0);
    });

    test('serialises tds under key "tds"', () {
      expect(json['tds'], 300.0);
    });

    test('serialises dissolvedOxygen under snake_case key "dissolved_oxygen"', () {
      expect(json['dissolved_oxygen'], 7.2,
          reason: '"dissolved_oxygen" (snake_case) — the backend will ignore '
              '"dissolvedOxygen" (camelCase) and store 0 instead');
    });

    test('serialises exactly 6 keys — no extra fields leak into the request', () {
      expect(json.length, 6,
          reason: 'Sending extra unknown keys is harmless but indicates a '
              'schema drift that should be caught early');
    });

    test('numeric values are preserved as doubles — not cast to int', () {
      // Some JSON encoders coerce 3.0 → 3 (int), breaking backends that
      // validate type: number not type: integer.
      expect(json['ph'],               isA<double>());
      expect(json['dissolved_oxygen'], isA<double>());
    });
  });

  // ── AnalysedReading ───────────────────────────────────────────────────────

  group('AnalysedReading · construction', () {
    const ph = AnalysedReading(
      parameter: 'PH',
      value:     3.0,
      result:    'LOW, The water is acidic, treat with alkaline solution',
    );

    test('stores parameter name unchanged', () {
      expect(ph.parameter, 'PH');
    });

    test('stores value as double', () {
      expect(ph.value, 3.0);
      expect(ph.value, isA<double>());
    });

    test('stores the full advisory result string', () {
      expect(ph.result, contains('acidic'));
    });
  });

  // ── ReadingUploadResponse ─────────────────────────────────────────────────

  group('ReadingUploadResponse · construction', () {
    final response = ReadingUploadResponse(
      message:  'Data analyzed and recorded',
      readings: [
        const AnalysedReading(parameter: 'PH',       value: 3.0, result: 'LOW'),
        const AnalysedReading(parameter: 'Turbidity', value: 4.0, result: 'OPTIMUM'),
      ],
    );

    test('stores message from backend', () {
      expect(response.message, 'Data analyzed and recorded');
    });

    test('stores all readings returned by the backend', () {
      expect(response.readings.length, 2);
    });

    test('readings are accessible by index', () {
      expect(response.readings[0].parameter, 'PH');
      expect(response.readings[1].parameter, 'Turbidity');
    });

    test('empty readings list does not throw', () {
      final empty = ReadingUploadResponse(message: 'ok', readings: []);
      expect(empty.readings, isEmpty);
    });
  });

  // ── ReadingUploadRequest field validation edge cases ──────────────────────

  group('ReadingUploadRequest · edge cases', () {
    test('zero values serialise correctly — pH=0 is a valid (extreme) reading', () {
      const req = ReadingUploadRequest(
        apiKey: 'AQ-test', ph: 0, temperature: 0,
        turbidity: 0, tds: 0, dissolvedOxygen: 0,
      );
      final json = req.toJson();
      expect(json['ph'], 0.0);
    });

    test('high-precision values are not rounded by toJson', () {
      const req = ReadingUploadRequest(
        apiKey: 'AQ-test', ph: 6.789, temperature: 0,
        turbidity: 0, tds: 0, dissolvedOxygen: 0,
      );
      expect(req.toJson()['ph'], 6.789);
    });
  });
}
