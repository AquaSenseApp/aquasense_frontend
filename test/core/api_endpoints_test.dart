import 'package:flutter_test/flutter_test.dart';
import 'package:aquasense/core/network/api_endpoints.dart';

void main() {
  group('ApiEndpoints', () {
    group('Base URL', () {
      test('should have a default base URL', () {
        expect(ApiEndpoints.baseUrl, isNotEmpty);
      });

      test('base URL should use HTTPS by default', () {
        expect(ApiEndpoints.baseUrl.startsWith('https://'), true);
      });
    });

    group('Authentication Endpoints', () {
      test('login should return correct path', () {
        expect(ApiEndpoints.login, '/api/users/login');
      });

      test('register should return correct path', () {
        expect(ApiEndpoints.register, '/api/users/register');
      });
    });

    group('Sensor Endpoints', () {
      test('registerSensor should return correct path', () {
        expect(ApiEndpoints.registerSensor, '/api/sensors/register');
      });

      test('sensorsByUser should return correct path with userId', () {
        final path = ApiEndpoints.sensorsByUser(123);
        expect(path, '/api/sensors/user/123');
      });

      test('sensorsByUser should handle different user IDs', () {
        expect(ApiEndpoints.sensorsByUser(1), '/api/sensors/user/1');
        expect(ApiEndpoints.sensorsByUser(999), '/api/sensors/user/999');
        expect(ApiEndpoints.sensorsByUser(0), '/api/sensors/user/0');
      });

      test('analyticsForUser should return correct path with userId', () {
        final path = ApiEndpoints.analyticsForUser(123);
        expect(path, '/api/sensors/analytics/123');
      });
    });

    group('Reading Endpoints', () {
      test('uploadReading should return correct path', () {
        expect(ApiEndpoints.uploadReading, '/api/readings/upload');
      });
    });

    group('Alert Endpoints', () {
      test('alertsByUser should return correct path with userId', () {
        final path = ApiEndpoints.alertsByUser(123);
        expect(path, '/api/alerts/user/123');
      });

      test('alertsByUser should handle different user IDs', () {
        expect(ApiEndpoints.alertsByUser(1), '/api/alerts/user/1');
        expect(ApiEndpoints.alertsByUser(456), '/api/alerts/user/456');
      });

      test('resolveAlert should return correct path with alertId', () {
        final path = ApiEndpoints.resolveAlert(789);
        expect(path, '/api/alerts/resolve/789');
      });

      test('resolveAlert should handle different alert IDs', () {
        expect(ApiEndpoints.resolveAlert(1), '/api/alerts/resolve/1');
        expect(ApiEndpoints.resolveAlert(100), '/api/alerts/resolve/100');
      });
    });

    group('Endpoint Patterns', () {
      test('all auth endpoints should start with /api/users', () {
        expect(ApiEndpoints.login.startsWith('/api/users'), true);
        expect(ApiEndpoints.register.startsWith('/api/users'), true);
      });

      test('all sensor endpoints should start with /api/sensors', () {
        expect(ApiEndpoints.registerSensor.startsWith('/api/sensors'), true);
        expect(ApiEndpoints.sensorsByUser(1).startsWith('/api/sensors'), true);
        expect(ApiEndpoints.analyticsForUser(1).startsWith('/api/sensors'), true);
      });

      test('all reading endpoints should start with /api/readings', () {
        expect(ApiEndpoints.uploadReading.startsWith('/api/readings'), true);
      });

      test('all alert endpoints should start with /api/alerts', () {
        expect(ApiEndpoints.alertsByUser(1).startsWith('/api/alerts'), true);
        expect(ApiEndpoints.resolveAlert(1).startsWith('/api/alerts'), true);
      });
    });
  });
}
