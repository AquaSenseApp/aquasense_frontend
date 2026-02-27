import 'package:flutter_test/flutter_test.dart';
import 'package:aquasense/models/sensor_model.dart';
import 'package:aquasense/repositories/sensor_repository.dart';

void main() {
  group('MockSensorRepository', () {
    late MockSensorRepository repository;

    setUp(() {
      repository = MockSensorRepository();
    });

    group('getSensors', () {
      test('should return list of sensors', () async {
        final sensors = await repository.getSensors();

        expect(sensors, isNotEmpty);
        expect(sensors.length, 4);
      });

      test('should return unmodifiable list', () async {
        final sensors = await repository.getSensors();

        expect(() => sensors.add(
          SensorModel(
            id: 'new',
            name: 'New',
            location: 'New',
            parameter: ParameterType.pH,
            riskLevel: RiskLevel.low,
            latestReading: SensorReading(
              value: 7.0,
              parameter: ParameterType.pH,
              trend: TrendDirection.stable,
              timestamp: DateTime.now(),
            ),
            advisory: const AiAdvisory(
              headline: 'Test',
              impactExplanation: 'Test',
              recommendedActions: [],
              impactNotes: '',
            ),
          ),
        ), throwsUnsupportedError);
      });

      test('should contain expected sensor types', () async {
        final sensors = await repository.getSensors();

        final parameters = sensors.map((s) => s.parameter).toSet();
        expect(parameters, contains(ParameterType.pH));
        expect(parameters, contains(ParameterType.turbidity));
      });
    });

    group('getSensorById', () {
      test('should return sensor when found', () async {
        final sensor = await repository.getSensorById('AQ-PH-203');

        expect(sensor, isNotNull);
        expect(sensor!.id, 'AQ-PH-203');
        expect(sensor.name, 'pH Sensor Alpha');
      });

      test('should return null when sensor not found', () async {
        final sensor = await repository.getSensorById('NON-EXISTENT');

        expect(sensor, isNull);
      });

      test('should return sensor with correct properties', () async {
        final sensor = await repository.getSensorById('AQ-PH-203');

        expect(sensor!.parameter, ParameterType.pH);
        expect(sensor.riskLevel, RiskLevel.high);
        expect(sensor.complianceStatus, ComplianceStatus.fail);
      });
    });

    group('addSensor', () {
      test('should add sensor to repository', () async {
        final form = AddSensorForm();
        form.parameterType = ParameterType.temperature;
        form.sensorId = 'AQ-TEMP-001';
        form.sensorName = 'Temperature Sensor';
        form.site = 'Lagos';
        form.specificLocation = 'Victoria Island';
        form.safeRange = '20 - 30';
        form.alertThreshold = AlertThreshold.warningLevel;
        form.aiAdvisoryEnabled = true;
        form.sensitivityLevel = RiskSensitivityLevel.medium;
        form.dataSourceType = DataSourceType.iot;

        final sensor = await repository.addSensor(form);

        expect(sensor.id, 'AQ-TEMP-001');
        expect(sensor.name, 'Temperature Sensor');
        expect(sensor.parameter, ParameterType.temperature);
      });

      test('should add sensor with GPS coordinates when provided', () async {
        final form = AddSensorForm();
        form.parameterType = ParameterType.pH;
        form.sensorId = 'AQ-PH-NEW';
        form.sensorName = 'New pH Sensor';
        form.site = 'Lagos';
        form.specificLocation = 'Test Location';
        form.gpsCoordinates = '6.5244, 3.3792';

        final sensor = await repository.addSensor(form);

        expect(sensor.gpsCoordinates, '6.5244, 3.3792');
      });

      test('should be retrievable after adding', () async {
        final form = AddSensorForm();
        form.parameterType = ParameterType.conductivity;
        form.sensorId = 'AQ-COND-NEW';
        form.sensorName = 'New Conductivity Sensor';
        form.site = 'Abuja';
        form.specificLocation = 'Central';

        await repository.addSensor(form);
        final sensor = await repository.getSensorById('AQ-COND-NEW');

        expect(sensor, isNotNull);
        expect(sensor!.name, 'New Conductivity Sensor');
      });
    });

    group('deleteSensor', () {
      test('should remove sensor from repository', () async {
        // Verify sensor exists
        var sensor = await repository.getSensorById('AQ-PH-203');
        expect(sensor, isNotNull);

        // Delete sensor
        await repository.deleteSensor('AQ-PH-203');

        // Verify sensor is removed
        sensor = await repository.getSensorById('AQ-PH-203');
        expect(sensor, isNull);
      });

      test('should handle deleting non-existent sensor gracefully', () async {
        // Should not throw
        await repository.deleteSensor('NON-EXISTENT');

        // Other sensors should still exist
        final sensors = await repository.getSensors();
        expect(sensors.length, 4); // Original 4 sensors still there
      });

      test('should only delete specified sensor', () async {
        await repository.deleteSensor('AQ-PH-203');

        final sensors = await repository.getSensors();
        expect(sensors.length, 3);
        expect(sensors.any((s) => s.id == 'AQ-PH-202'), true);
        expect(sensors.any((s) => s.id == 'AQ-TUR-145'), true);
        expect(sensors.any((s) => s.id == 'AQ-TUR-146'), true);
      });
    });
  });
}
