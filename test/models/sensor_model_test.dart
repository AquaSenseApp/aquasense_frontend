import 'package:flutter_test/flutter_test.dart';
import 'package:aquasense/models/sensor_model.dart';

void main() {
  group('RiskLevel', () {
    test('label returns correct string for each enum value', () {
      expect(RiskLevel.low.label, 'low');
      expect(RiskLevel.medium.label, 'medium');
      expect(RiskLevel.high.label, 'high');
    });
  });

  group('ParameterType', () {
    test('label returns correct string for each enum value', () {
      expect(ParameterType.pH.label, 'pH');
      expect(ParameterType.turbidity.label, 'Turbidity');
      expect(ParameterType.dissolvedOxygen.label, 'Dissolved Oxygen');
      expect(ParameterType.temperature.label, 'Temperature');
      expect(ParameterType.conductivity.label, 'Conductivity');
      expect(ParameterType.other.label, 'Other');
    });

    test('unit returns correct string for each enum value', () {
      expect(ParameterType.pH.unit, 'pH');
      expect(ParameterType.turbidity.unit, 'NTU');
      expect(ParameterType.dissolvedOxygen.unit, 'mg/L');
      expect(ParameterType.temperature.unit, '°C');
      expect(ParameterType.conductivity.unit, 'µS/cm');
      expect(ParameterType.other.unit, '');
    });
  });

  group('DataSourceType', () {
    test('label returns correct string for each enum value', () {
      expect(DataSourceType.iot.label, 'IoT Device');
      expect(DataSourceType.manual.label, 'Manual Entry');
      expect(DataSourceType.modbus.label, 'Modbus');
      expect(DataSourceType.mqtt.label, 'MQTT');
    });
  });

  group('RiskSensitivityLevel', () {
    test('label returns correct string for each enum value', () {
      expect(RiskSensitivityLevel.low.label, 'Low');
      expect(RiskSensitivityLevel.medium.label, 'Medium');
      expect(RiskSensitivityLevel.high.label, 'High');
    });
  });

  group('AlertThreshold', () {
    test('label returns correct string for each enum value', () {
      expect(AlertThreshold.warningLevel.label, 'Warning Level');
      expect(AlertThreshold.criticalLevel.label, 'Critical Level');
    });
  });

  group('ComplianceStatus', () {
    test('label returns correct string for each enum value', () {
      expect(ComplianceStatus.pass.label, 'Pass');
      expect(ComplianceStatus.fail.label, 'Fail');
    });
  });

  group('SensorReading', () {
    test('displayValue returns formatted string', () {
      final reading = SensorReading(
        value: 7.2,
        parameter: ParameterType.pH,
        trend: TrendDirection.up,
        timestamp: DateTime(2024, 1, 1),
      );

      expect(reading.displayValue, '7.2 pH');
    });

    test('displayValue returns correct unit for turbidity', () {
      final reading = SensorReading(
        value: 2.3,
        parameter: ParameterType.turbidity,
        trend: TrendDirection.down,
        timestamp: DateTime(2024, 1, 1),
      );

      expect(reading.displayValue, '2.3 NTU');
    });

    test('displayValue returns correct unit for dissolved oxygen', () {
      final reading = SensorReading(
        value: 8.5,
        parameter: ParameterType.dissolvedOxygen,
        trend: TrendDirection.stable,
        timestamp: DateTime(2024, 1, 1),
      );

      expect(reading.displayValue, '8.5 mg/L');
    });
  });

  group('AiAdvisory', () {
    test('should create AiAdvisory with all fields', () {
      const advisory = AiAdvisory(
        headline: 'Test Headline',
        impactExplanation: 'Test Explanation',
        recommendedActions: ['Action 1', 'Action 2'],
        impactNotes: 'Test Notes',
      );

      expect(advisory.headline, 'Test Headline');
      expect(advisory.impactExplanation, 'Test Explanation');
      expect(advisory.recommendedActions, ['Action 1', 'Action 2']);
      expect(advisory.impactNotes, 'Test Notes');
    });

    test('should handle empty recommended actions', () {
      const advisory = AiAdvisory(
        headline: 'Test Headline',
        impactExplanation: 'Test Explanation',
        recommendedActions: [],
        impactNotes: 'Test Notes',
      );

      expect(advisory.recommendedActions, isEmpty);
    });
  });

  group('SensorModel', () {
    late SensorModel sensor;

    setUp(() {
      sensor = SensorModel(
        id: 'AQ-PH-001',
        apiId: 1,
        name: 'pH Sensor Alpha',
        location: 'Amuwo Odofin, Lagos',
        parameter: ParameterType.pH,
        riskLevel: RiskLevel.high,
        latestReading: SensorReading(
          value: 7.2,
          parameter: ParameterType.pH,
          trend: TrendDirection.up,
          timestamp: DateTime(2024, 1, 1),
        ),
        advisory: const AiAdvisory(
          headline: 'Test Headline',
          impactExplanation: 'Test Explanation',
          recommendedActions: ['Action 1'],
          impactNotes: 'Test Notes',
        ),
        complianceStatus: ComplianceStatus.fail,
        aiAdvisoryEnabled: true,
        gpsCoordinates: '6.5244, 3.3792',
        dataSource: DataSourceType.iot,
        sensitivityLevel: RiskSensitivityLevel.high,
        safeRange: '6.5 - 8.5',
        alertThreshold: AlertThreshold.criticalLevel,
      );
    });

    test('should create SensorModel with required fields', () {
      expect(sensor.id, 'AQ-PH-001');
      expect(sensor.apiId, 1);
      expect(sensor.name, 'pH Sensor Alpha');
      expect(sensor.location, 'Amuwo Odofin, Lagos');
      expect(sensor.parameter, ParameterType.pH);
      expect(sensor.riskLevel, RiskLevel.high);
    });

    test('copyWith should create a new instance with updated fields', () {
      final updated = sensor.copyWith(
        name: 'Updated Name',
        riskLevel: RiskLevel.low,
      );

      expect(updated.name, 'Updated Name');
      expect(updated.riskLevel, RiskLevel.low);
      expect(updated.id, sensor.id); // unchanged
      expect(updated.location, sensor.location); // unchanged
    });

    test('should use default values when not provided', () {
      final defaultSensor = SensorModel(
        id: 'AQ-TEST-001',
        name: 'Test Sensor',
        location: 'Test Location',
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

      expect(defaultSensor.complianceStatus, ComplianceStatus.pass);
      expect(defaultSensor.aiAdvisoryEnabled, true);
      expect(defaultSensor.dataSource, DataSourceType.iot);
      expect(defaultSensor.sensitivityLevel, RiskSensitivityLevel.medium);
      expect(defaultSensor.safeRange, '');
      expect(defaultSensor.alertThreshold, isNull);
    });
  });

  group('AddSensorForm', () {
    test('step1Valid returns true when all required fields are filled', () {
      final form = AddSensorForm();
      form.parameterType = ParameterType.pH;
      form.sensorId = 'AQ-PH-001';
      form.sensorName = 'Test Sensor';

      expect(form.step1Valid, true);
    });

    test('step1Valid returns false when parameterType is null', () {
      final form = AddSensorForm();
      form.sensorId = 'AQ-PH-001';
      form.sensorName = 'Test Sensor';

      expect(form.step1Valid, false);
    });

    test('step1Valid returns false when sensorId is empty', () {
      final form = AddSensorForm();
      form.parameterType = ParameterType.pH;
      form.sensorName = 'Test Sensor';

      expect(form.step1Valid, false);
    });

    test('step1Valid returns false when sensorName is empty', () {
      final form = AddSensorForm();
      form.parameterType = ParameterType.pH;
      form.sensorId = 'AQ-PH-001';

      expect(form.step1Valid, false);
    });

    test('step2Valid returns true when all required fields are filled', () {
      final form = AddSensorForm();
      form.site = 'Lagos';
      form.specificLocation = 'Amuwo Odofin';

      expect(form.step2Valid, true);
    });

    test('step2Valid returns false when site is empty', () {
      final form = AddSensorForm();
      form.specificLocation = 'Amuwo Odofin';

      expect(form.step2Valid, false);
    });

    test('step2Valid returns false when specificLocation is empty', () {
      final form = AddSensorForm();
      form.site = 'Lagos';

      expect(form.step2Valid, false);
    });

    test('step3Valid always returns true (configuration is optional)', () {
      final form = AddSensorForm();

      expect(form.step3Valid, true);
    });
  });
}
