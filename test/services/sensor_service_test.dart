import 'package:flutter_test/flutter_test.dart';
import 'package:aquasense/services/sensor_service.dart';
import 'package:aquasense/models/sensor_model.dart';

void main() {
  group('RegisteredSensor', () {
    test('should create RegisteredSensor with all fields', () {
      const registered = RegisteredSensor(
        sensorId: 123,
        apiKey: 'test-api-key',
        message: 'Sensor registered successfully',
      );

      expect(registered.sensorId, 123);
      expect(registered.apiKey, 'test-api-key');
      expect(registered.message, 'Sensor registered successfully');
    });
  });

  group('ApiSensorDto', () {
    test('fromJson creates instance with required fields', () {
      final json = {
        'id': 1,
        'sensor_name': 'pH Sensor Alpha',
        'sensor_type': 'pH',
        'location': 'Lagos',
        'apiKey': 'test-key',
        'UserId': 123,
      };

      final dto = ApiSensorDto.fromJson(json);

      expect(dto.id, 1);
      expect(dto.name, 'pH Sensor Alpha');
      expect(dto.type, 'pH');
      expect(dto.location, 'Lagos');
      expect(dto.apiKey, 'test-key');
      expect(dto.userId, 123);
    });

    test('fromJson handles alternative field names', () {
      final json = {
        'id': 2,
        'name': 'Turbidity Sensor',
        'type': 'Turbidity',
        'location': 'Abuja',
        'apiKey': 'key-456',
        'userId': 456,
      };

      final dto = ApiSensorDto.fromJson(json);

      expect(dto.name, 'Turbidity Sensor');
      expect(dto.userId, 456);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 3,
      };

      final dto = ApiSensorDto.fromJson(json);

      expect(dto.name, '');
      expect(dto.type, '');
      expect(dto.location, '');
      expect(dto.apiKey, '');
      expect(dto.userId, 0);
    });

    group('parameterType', () {
      test('returns pH for ph sensor type', () {
        final dto = ApiSensorDto.fromJson({
          'id': 1,
          'sensor_type': 'pH',
          'name': 'Test',
          'location': '',
          'apiKey': '',
          'userId': 1,
        });

        expect(dto.parameterType, ParameterType.pH);
      });

      test('returns pH for case-insensitive ph', () {
        final dto = ApiSensorDto.fromJson({
          'id': 1,
          'sensor_type': 'PH',
          'name': 'Test',
          'location': '',
          'apiKey': '',
          'userId': 1,
        });

        expect(dto.parameterType, ParameterType.pH);
      });

      test('returns turbidity for turbid sensor type', () {
        final dto = ApiSensorDto.fromJson({
          'id': 1,
          'sensor_type': 'Turbidity',
          'name': 'Test',
          'location': '',
          'apiKey': '',
          'userId': 1,
        });

        expect(dto.parameterType, ParameterType.turbidity);
      });

      test('returns turbidity for turbid substring', () {
        final dto = ApiSensorDto.fromJson({
          'id': 1,
          'sensor_type': 'Turbid',
          'name': 'Test',
          'location': '',
          'apiKey': '',
          'userId': 1,
        });

        expect(dto.parameterType, ParameterType.turbidity);
      });

      test('returns dissolvedOxygen for oxygen sensor type', () {
        final dto = ApiSensorDto.fromJson({
          'id': 1,
          'sensor_type': 'Dissolved Oxygen',
          'name': 'Test',
          'location': '',
          'apiKey': '',
          'userId': 1,
        });

        expect(dto.parameterType, ParameterType.dissolvedOxygen);
      });

      test('returns temperature for temp sensor type', () {
        final dto = ApiSensorDto.fromJson({
          'id': 1,
          'sensor_type': 'Temperature',
          'name': 'Test',
          'location': '',
          'apiKey': '',
          'userId': 1,
        });

        expect(dto.parameterType, ParameterType.temperature);
      });

      test('returns conductivity for conduct sensor type', () {
        final dto = ApiSensorDto.fromJson({
          'id': 1,
          'sensor_type': 'Conductivity',
          'name': 'Test',
          'location': '',
          'apiKey': '',
          'userId': 1,
        });

        expect(dto.parameterType, ParameterType.conductivity);
      });

      test('returns other for unknown sensor type', () {
        final dto = ApiSensorDto.fromJson({
          'id': 1,
          'sensor_type': 'Unknown Type',
          'name': 'Test',
          'location': '',
          'apiKey': '',
          'userId': 1,
        });

        expect(dto.parameterType, ParameterType.other);
      });
    });
  });
}
