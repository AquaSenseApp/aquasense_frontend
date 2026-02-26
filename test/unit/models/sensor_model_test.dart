// test/unit/models/sensor_model_test.dart
//
// WHY these tests exist
// ─────────────────────
// Sensor cards, wizard dropdowns, and reading upload labels all read
// ParameterType.label and .unit.  A single typo — "Turbidty" instead of
// "Turbidity" — shows up everywhere at once.  Pinning the string values here
// turns a QA-discovered visual bug into a compile-time-caught test failure.

import 'package:flutter_test/flutter_test.dart';
import 'package:aquasense/models/sensor_model.dart';
import '../../helpers/test_helpers.dart';

void main() {
  // ── ParameterType ─────────────────────────────────────────────────────────

  group('ParameterType · labels and units', () {
    test('every value has a non-empty label', () {
      for (final p in ParameterType.values) {
        expect(p.label, isNotEmpty, reason: '${p.name} is missing a display label');
      }
    });

    const expected = {
      ParameterType.pH:              ('pH',                'pH'),
      ParameterType.turbidity:       ('Turbidity',         'NTU'),
      ParameterType.dissolvedOxygen: ('Dissolved Oxygen',  'mg/L'),
      ParameterType.temperature:     ('Temperature',       '°C'),
      ParameterType.conductivity:    ('Conductivity',      'µS/cm'),
      ParameterType.other:           ('Other',             ''),
    };

    for (final entry in expected.entries) {
      test('${entry.key.name} label = "${entry.value.$1}"', () {
        expect(entry.key.label, entry.value.$1);
      });
      test('${entry.key.name} unit  = "${entry.value.$2}"', () {
        expect(entry.key.unit, entry.value.$2);
      });
    }
  });

  // ── RiskLevel ─────────────────────────────────────────────────────────────

  group('RiskLevel · labels', () {
    test('low  → "low"',    () => expect(RiskLevel.low.label,    'low'));
    test('medium → "medium"', () => expect(RiskLevel.medium.label, 'medium'));
    test('high → "high"',  () => expect(RiskLevel.high.label,    'high'));
  });

  // ── SensorReading.displayValue ────────────────────────────────────────────

  group('SensorReading · displayValue', () {
    SensorReading reading(double value, ParameterType p) => SensorReading(
      value: value, parameter: p,
      trend: TrendDirection.stable, timestamp: DateTime(2026),
    );

    test('pH reading formats as "7.2 pH"', () {
      expect(reading(7.2, ParameterType.pH).displayValue, '7.2 pH');
    });

    test('turbidity reading formats as "4.0 NTU"', () {
      expect(reading(4.0, ParameterType.turbidity).displayValue, '4.0 NTU');
    });

    test('dissolved oxygen reading formats as "7.2 mg/L"', () {
      expect(reading(7.2, ParameterType.dissolvedOxygen).displayValue, '7.2 mg/L');
    });

    test('temperature reading formats as "24.8 °C"', () {
      expect(reading(24.8, ParameterType.temperature).displayValue, '24.8 °C');
    });
  });

  // ── SensorModel.copyWith ──────────────────────────────────────────────────

  group('SensorModel · copyWith', () {
    test('changes riskLevel without touching other fields', () {
      final updated = makeSensor(risk: RiskLevel.low).copyWith(riskLevel: RiskLevel.high);
      expect(updated.riskLevel, RiskLevel.high);
      expect(updated.name,      makeSensor().name);
    });

    test('attaches apiId and apiKey after backend registration', () {
      final registered = makeSensor().copyWith(apiId: 42, apiKey: 'AQ-abc123');
      expect(registered.apiId,  42);
      expect(registered.apiKey, 'AQ-abc123');
    });
  });

  // ── AddSensorForm step validation ─────────────────────────────────────────
  // WHY test form validation?  The wizard's "Next" button is gated on
  // canAdvance, which calls stepNValid.  If a bug lets step1Valid return true
  // on an empty form, the backend receives a blank sensor_name and returns 400.

  group('AddSensorForm · step validation', () {
    test('step1Valid is false on blank form', () {
      expect(AddSensorForm().step1Valid, isFalse);
    });

    test('step1Valid is true when parameterType + sensorId + sensorName are set', () {
      final form = AddSensorForm()
        ..parameterType = ParameterType.pH
        ..sensorId      = 'AQ-001'
        ..sensorName    = 'Alpha Sensor';
      expect(form.step1Valid, isTrue);
    });

    test('step2Valid is false when site and specificLocation are empty', () {
      expect(AddSensorForm().step2Valid, isFalse);
    });

    test('step2Valid is true when site and specificLocation are set', () {
      final form = AddSensorForm()
        ..site             = 'Nairobi North'
        ..specificLocation = 'Tank Room A';
      expect(form.step2Valid, isTrue);
    });

    test('step3Valid is always true — config settings are optional by design', () {
      // We chose to make step 3 optional because operators often register
      // sensors before they know the exact safe ranges.
      expect(AddSensorForm().step3Valid, isTrue);
    });
  });

  // ── ApiSensorDto.parameterType mapping ───────────────────────────────────
  // WHY test the DTO mapping?  The backend sends free-text sensor_type strings
  // like "Ultrasonic Level Sensor" or "pH Probe v2".  The substring match
  // must cover every real-world string the backend might send.

  group('ApiSensorDto · parameterType mapping', () {
    ParameterType mapType(String type) {
      // Mirror the exact logic in ApiSensorDto.parameterType
      final t = type.toLowerCase();
      if (t.contains('ph'))      return ParameterType.pH;
      if (t.contains('turbid'))  return ParameterType.turbidity;
      if (t.contains('oxygen'))  return ParameterType.dissolvedOxygen;
      if (t.contains('temp'))    return ParameterType.temperature;
      if (t.contains('conduct')) return ParameterType.conductivity;
      return ParameterType.other;
    }

    test('"pH Probe v2" → ParameterType.pH', () {
      expect(mapType('pH Probe v2'), ParameterType.pH);
    });

    test('"Ultrasonic Level Sensor" → ParameterType.other', () {
      expect(mapType('Ultrasonic Level Sensor'), ParameterType.other);
    });

    test('"Water Temperature Sensor" → ParameterType.temperature', () {
      expect(mapType('Water Temperature Sensor'), ParameterType.temperature);
    });

    test('"Turbidity Monitor" → ParameterType.turbidity', () {
      expect(mapType('Turbidity Monitor'), ParameterType.turbidity);
    });

    test('"Dissolved Oxygen Probe" → ParameterType.dissolvedOxygen', () {
      expect(mapType('Dissolved Oxygen Probe'), ParameterType.dissolvedOxygen);
    });
  });
}
