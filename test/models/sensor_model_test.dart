import 'package:flutter_test/flutter_test.dart';
import 'package:aquasense/models/sensor_model.dart';

void main() {
  group('RiskLevel', () {
    test('should return correct label for low risk', () {
      expect(RiskLevel.low.label, 'low');
    });

    test('should return correct label for medium risk', () {
      expect(RiskLevel.medium.label, 'medium');
    });

    test('should return correct label for high risk', () {
      expect(RiskLevel.high.label, 'high');
    });
  });

  group('ParameterType', () {
    test('should return correct label for pH', () {
      expect(ParameterType.pH.label, 'pH');
    });

    test('should return correct label for turbidity', () {
      expect(ParameterType.turbidity.label, 'Turbidity');
    });

    test('should return correct label for dissolved oxygen', () {
      expect(ParameterType.dissolvedOxygen.label, 'Dissolved Oxygen');
    });

    test('should return correct label for temperature', () {
      expect(ParameterType.temperature.label, 'Temperature');
    });

    test('should return correct label for conductivity', () {
      expect(ParameterType.conductivity.label, 'Conductivity');
    });

    test('should return correct unit for pH', () {
      expect(ParameterType.pH.unit, 'pH');
    });

    test('should return correct unit for turbidity', () {
      expect(ParameterType.turbidity.unit, 'NTU');
    });

    test('should return correct unit for dissolved oxygen', () {
      expect(ParameterType.dissolvedOxygen.unit, 'mg/L');
    });

    test('should return correct unit for temperature', () {
      expect(ParameterType.temperature.unit, '°C');
    });

    test('should return correct unit for conductivity', () {
      expect(ParameterType.conductivity.unit, 'µS/cm');
    });
  });

  group('DataSourceType', () {
    test('should return correct label for iot', () {
      expect(DataSourceType.iot.label, 'IoT Device');
    });

    test('should return correct label for manual', () {
      expect(DataSourceType.manual.label, 'Manual Entry');
    });

    test('should return correct label for modbus', () {
      expect(DataSourceType.modbus.label, 'Modbus');
    });

    test('should return correct label for mqtt', () {
      expect(DataSourceType.mqtt.label, 'MQTT');
    });
  });

  group('RiskSensitivityLevel', () {
    test('should return correct label for low', () {
      expect(RiskSensitivityLevel.low.label, 'Low');
    });

    test('should return correct label for medium', () {
      expect(RiskSensitivityLevel.medium.label, 'Medium');
    });

    test('should return correct label for high', () {
      expect(RiskSensitivityLevel.high.label, 'High');
    });
  });

  group('AlertThreshold', () {
    test('should return correct label for warning level', () {
      expect(AlertThreshold.warningLevel.label, 'Warning Level');
    });

    test('should return correct label for critical level', () {
      expect(AlertThreshold.criticalLevel.label, 'Critical Level');
    });
  });

  group('ComplianceStatus', () {
    test('should return correct label for pass', () {
      expect(ComplianceStatus.pass.label, 'Pass');
    });

    test('should return correct label for fail', () {
      expect(ComplianceStatus.fail.label, 'Fail');
    });
  });

  group('SensorReading', () {
    test('should create SensorReading with required parameters', () {
      final reading = SensorReading(
        value: 7.0,
        parameter: ParameterType.pH,
        trend: TrendDirection.stable,
        timestamp: DateTime(2024, 1, 1),
      );

      expect(reading.value, 7.0);
      expect(reading.parameter, ParameterType.pH);
      expect(reading.trend, TrendDirection.stable);
      expect(reading.timestamp, DateTime(2024, 1, 1));
    });

    test('should return correct display value', () {
      final reading = SensorReading(
        value: 7.5,
        parameter: ParameterType.pH,
        trend: TrendDirection.up,
        timestamp: DateTime(2024, 1, 1),
      );

      expect(reading.displayValue, '7.5 pH');
    });

    test('should return correct display value for turbidity', () {
      final reading = SensorReading(
        value: 4.2,
        parameter: ParameterType.turbidity,
        trend: TrendDirection.down,
        timestamp: DateTime(2024, 1, 1),
      );

      expect(reading.displayValue, '4.2 NTU');
    });
  });

  group('AiAdvisory', () {
    test('should create AiAdvisory with all required parameters', () {
      const advisory = AiAdvisory(
        headline: 'pH Level Warning',
        impactExplanation: 'The pH level is above recommended thresholds',
        recommendedActions: ['Check chemical dosing', 'Inspect influent'],
        impactNotes: 'May affect biological treatment process',
      );

      expect(advisory.headline, 'pH Level Warning');
      expect(advisory.impactExplanation, 'The pH level is above recommended thresholds');
      expect(advisory.recommendedActions.length, 2);
      expect(advisory.recommendedActions[0], 'Check chemical dosing');
      expect(advisory.impactNotes, 'May affect biological treatment process');
    });
  });

  group('SensorModel', () {
    late SensorModel sensor;

    setUp(() {
      sensor = SensorModel(
        id: 'sensor-123',
        apiId: 123,
        apiKey: 'api-key-456',
        name: 'pH Sensor 1',
        location: 'Treatment Plant A',
        parameter: ParameterType.pH,
        riskLevel: RiskLevel.medium,
        latestReading: SensorReading(
          value: 7.2,
          parameter: ParameterType.pH,
          trend: TrendDirection.stable,
          timestamp: DateTime(2024, 1, 1),
        ),
        advisory: const AiAdvisory(
          headline: 'Normal Operation',
          impactExplanation: 'All parameters within range',
          recommendedActions: [],
          impactNotes: '',
        ),
        complianceStatus: ComplianceStatus.pass,
        aiAdvisoryEnabled: true,
        gpsCoordinates: '40.7128,-74.0060',
        dataSource: DataSourceType.iot,
        sensitivityLevel: RiskSensitivityLevel.medium,
        safeRange: '6.5 - 8.0',
        alertThreshold: AlertThreshold.warningLevel,
      );
    });

    test('should create SensorModel with all parameters', () {
      expect(sensor.id, 'sensor-123');
      expect(sensor.apiId, 123);
      expect(sensor.apiKey, 'api-key-456');
      expect(sensor.name, 'pH Sensor 1');
      expect(sensor.location, 'Treatment Plant A');
      expect(sensor.parameter, ParameterType.pH);
      expect(sensor.riskLevel, RiskLevel.medium);
      expect(sensor.complianceStatus, ComplianceStatus.pass);
      expect(sensor.aiAdvisoryEnabled, true);
      expect(sensor.gpsCoordinates, '40.7128,-74.0060');
      expect(sensor.dataSource, DataSourceType.iot);
      expect(sensor.sensitivityLevel, RiskSensitivityLevel.medium);
      expect(sensor.safeRange, '6.5 - 8.0');
      expect(sensor.alertThreshold, AlertThreshold.warningLevel);
    });

    test('should create SensorModel with default values', () {
      final defaultSensor = SensorModel(
        id: 'sensor-456',
        name: 'Default Sensor',
        location: 'Location',
        parameter: ParameterType.pH,
        riskLevel: RiskLevel.low,
        latestReading: SensorReading(
          value: 7.0,
          parameter: ParameterType.pH,
          trend: TrendDirection.stable,
          timestamp: DateTime(2024, 1, 1),
        ),
        advisory: const AiAdvisory(
          headline: 'Test',
          impactExplanation: 'Test',
          recommendedActions: [],
          impactNotes: '',
        ),
      );

      expect(defaultSensor.apiId, null);
      expect(defaultSensor.apiKey, null);
      expect(defaultSensor.complianceStatus, ComplianceStatus.pass);
      expect(defaultSensor.aiAdvisoryEnabled, true);
      expect(defaultSensor.gpsCoordinates, null);
      expect(defaultSensor.dataSource, DataSourceType.iot);
      expect(defaultSensor.sensitivityLevel, RiskSensitivityLevel.medium);
      expect(defaultSensor.safeRange, '');
      expect(defaultSensor.alertThreshold, null);
    });

    test('copyWith should create a new instance with updated values', () {
      final updated = sensor.copyWith(
        name: 'Updated Sensor Name',
        riskLevel: RiskLevel.high,
        location: 'New Location',
      );

      expect(updated.id, sensor.id);
      expect(updated.name, 'Updated Sensor Name');
      expect(updated.riskLevel, RiskLevel.high);
      expect(updated.location, 'New Location');
      expect(updated.parameter, sensor.parameter);
    });

    test('copyWith should preserve values when not specified', () {
      final updated = sensor.copyWith(name: 'New Name');

      expect(updated.apiId, sensor.apiId);
      expect(updated.apiKey, sensor.apiKey);
      expect(updated.location, sensor.location);
      expect(updated.parameter, sensor.parameter);
      expect(updated.riskLevel, sensor.riskLevel);
      expect(updated.complianceStatus, sensor.complianceStatus);
      expect(updated.aiAdvisoryEnabled, sensor.aiAdvisoryEnabled);
    });
  });

  group('AddSensorForm', () {
    test('should create AddSensorForm with empty values', () {
      final form = AddSensorForm();

      expect(form.parameterType, null);
      expect(form.sensorId, '');
      expect(form.sensorName, '');
      expect(form.site, '');
      expect(form.specificLocation, '');
      expect(form.gpsCoordinates, '');
      expect(form.dataSourceType, null);
      expect(form.safeRange, '');
      expect(form.alertThreshold, null);
      expect(form.aiAdvisoryEnabled, false);
      expect(form.sensitivityLevel, null);
    });

    test('step1Valid should return false when required fields are empty', () {
      final form = AddSensorForm();

      expect(form.step1Valid, false);
    });

    test('step1Valid should return true when all required fields are filled', () {
      final form = AddSensorForm()
        ..parameterType = ParameterType.pH
        ..sensorId = 'sensor-001'
        ..sensorName = 'Test Sensor';

      expect(form.step1Valid, true);
    });

    test('step1Valid should return false when only parameterType is set', () {
      final form = AddSensorForm()..parameterType = ParameterType.pH;

      expect(form.step1Valid, false);
    });

    test('step2Valid should return false when required fields are empty', () {
      final form = AddSensorForm();

      expect(form.step2Valid, false);
    });

    test('step2Valid should return true when location fields are filled', () {
      final form = AddSensorForm()
        ..site = 'Treatment Plant A'
        ..specificLocation = 'Inlet';

      expect(form.step2Valid, true);
    });

    test('step3Valid should always return true (optional fields)', () {
      final form = AddSensorForm();

      expect(form.step3Valid, true);
    });
  });
}
