import 'package:flutter_test/flutter_test.dart';
import 'package:aquasense/core/network/api_endpoints.dart';

void main() {
  group('ApiEndpoints', () {
    test('baseUrl has a default production value', () {
      expect(ApiEndpoints.baseUrl, isNotEmpty);
      expect(ApiEndpoints.baseUrl.startsWith('https://'), true);
    });

    group('Auth endpoints', () {
      test('login returns correct path', () {
        expect(ApiEndpoints.login, '/api/users/login');
      });

      test('register returns correct path', () {
        expect(ApiEndpoints.register, '/api/users/register');
      });
    });

    group('Sensor endpoints', () {
      test('registerSensor returns correct path', () {
        expect(ApiEndpoints.registerSensor, '/api/sensors/register');
      });

      test('sensorsByUser returns correct path with userId', () {
        expect(ApiEndpoints.sensorsByUser(123), '/api/sensors/user/123');
      });

      test('sensorsByUser returns correct path with different userId', () {
        expect(ApiEndpoints.sensorsByUser(456), '/api/sensors/user/456');
      });

      
    });

    group('Reading endpoints', () {
      test('uploadReading returns correct path', () {
        expect(ApiEndpoints.uploadReading, '/api/readings/upload');
      });
    });

    group('Alert endpoints', () {
      test('alertsByUser returns correct path with userId', () {
        expect(ApiEndpoints.alertsByUser(123), '/api/alerts/user/123');
      });

      test('resolveAlert returns correct path with alertId', () {
        expect(ApiEndpoints.resolveAlert(456), '/api/alerts/resolve/456');
      });
    });
  });
}
