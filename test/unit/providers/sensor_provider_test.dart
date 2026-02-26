// test/unit/providers/sensor_provider_test.dart
//
// WHY these tests exist
// ─────────────────────
// SensorProvider owns the wizard state machine, per-screen search scoping,
// and the updateUser guard.  The wizard step machine is especially important:
// if canAdvance returns true on step 0 without a sensorName, the backend
// receives sensor_name="" and returns an opaque 400 error.

import 'package:flutter_test/flutter_test.dart';
import 'package:aquasense/models/sensor_model.dart';
import 'package:aquasense/models/user_model.dart';
import 'package:aquasense/providers/sensor_provider.dart';
import '../../helpers/test_helpers.dart';

void main() {
  late SensorProvider provider;

  setUp(() {
    setupFakeSharedPrefs();
    provider = SensorProvider(null); // no user → no auto-load
  });

  // ── Initial state ─────────────────────────────────────────────────────────

  group('SensorProvider · initial state', () {
    test('sensors list starts empty', () {
      expect(provider.sensors, isEmpty);
    });

    test('loadState starts as initial', () {
      expect(provider.loadState, LoadState.initial);
    });

    test('isLoading is false initially', () {
      expect(provider.isLoading, isFalse);
    });

    test('wizardStep starts at 0', () {
      expect(provider.wizardStep, 0);
    });
  });

  // ── Wizard state machine ──────────────────────────────────────────────────

  group('SensorProvider · wizard navigation', () {
    test('nextWizardStep advances from 0 to 1', () {
      provider.nextWizardStep();
      expect(provider.wizardStep, 1);
    });

    test('prevWizardStep cannot go below 0', () {
      provider.prevWizardStep();
      expect(provider.wizardStep, 0,
          reason: 'Pressing Back on the first step must be a no-op');
    });

    test('nextWizardStep cannot exceed lastWizardStep', () {
      for (var i = 0; i < SensorProvider.totalWizardSteps + 5; i++) {
        provider.nextWizardStep();
      }
      expect(provider.wizardStep, SensorProvider.lastWizardStep,
          reason: 'Step index must be clamped at the final step');
    });

    test('isLastStep is false on step 0', () {
      expect(provider.isLastStep, isFalse);
    });

    test('isLastStep is true on the final step', () {
      for (var i = 0; i < SensorProvider.lastWizardStep; i++) {
        provider.nextWizardStep();
      }
      expect(provider.isLastStep, isTrue);
    });

    test('resetWizard returns to step 0 and clears form', () {
      provider.nextWizardStep();
      provider.form.sensorName = 'Old name';

      provider.resetWizard();

      expect(provider.wizardStep,    0);
      expect(provider.form.sensorName, isEmpty);
    });

    test('nextWizardStep notifies listeners', () {
      var notified = false;
      provider.addListener(() => notified = true);
      provider.nextWizardStep();
      expect(notified, isTrue);
    });
  });

  // ── canAdvance gating ─────────────────────────────────────────────────────

  group('SensorProvider · canAdvance', () {
    test('step 0 — false on blank form', () {
      expect(provider.canAdvance, isFalse);
    });

    test('step 0 — true after filling required step-1 fields', () {
      provider.form
        ..parameterType = ParameterType.pH
        ..sensorId      = 'AQ-001'
        ..sensorName    = 'Alpha';
      provider.updateForm();

      expect(provider.canAdvance, isTrue);
    });

    test('step 1 — false when site and specificLocation are empty', () {
      // Advance to step 1 with a valid step 0
      provider.form
        ..parameterType = ParameterType.pH
        ..sensorId      = 'AQ-001'
        ..sensorName    = 'Alpha';
      provider.nextWizardStep();

      expect(provider.canAdvance, isFalse);
    });

    test('step 1 — true after filling site and specificLocation', () {
      provider.form
        ..parameterType    = ParameterType.pH
        ..sensorId         = 'AQ-001'
        ..sensorName       = 'Alpha'
        ..site             = 'Nairobi North'
        ..specificLocation = 'Tank Room A';
      provider.nextWizardStep();
      provider.updateForm();

      expect(provider.canAdvance, isTrue);
    });

    test('steps 2–4 always return true (optional fields)', () {
      // Fill mandatory earlier steps
      provider.form
        ..parameterType    = ParameterType.pH
        ..sensorId         = 'AQ-001'
        ..sensorName       = 'Alpha'
        ..site             = 'Site'
        ..specificLocation = 'Loc';

      provider.nextWizardStep(); // → step 1
      provider.nextWizardStep(); // → step 2
      expect(provider.canAdvance, isTrue,
          reason: 'Step 2 (config) is optional — Next must always be enabled');

      provider.nextWizardStep(); // → step 3
      expect(provider.canAdvance, isTrue);

      provider.nextWizardStep(); // → step 4
      expect(provider.canAdvance, isTrue);
    });
  });

  // ── Per-screen search scoping ─────────────────────────────────────────────

  group('SensorProvider · scoped search', () {
    setUp(() {
      provider.setSensorsForTest([
        makeSensor(id: 'AQ-PH-001', name: 'Alpha Sensor',  location: 'Nairobi'),
        makeSensor(id: 'AQ-TB-002', name: 'Beta Monitor',  location: 'Lagos'),
        makeSensor(id: 'AQ-DO-003', name: 'Gamma Probe',   location: 'Nairobi'),
      ]);
    });

    test('home scope query does not affect sensors scope', () {
      provider.setSearchQuery('Alpha', scope: SensorSearchScope.home);

      expect(
        provider.filteredSensors(scope: SensorSearchScope.sensors).length, 3,
        reason: 'Home and Sensors tabs own independent search states',
      );
    });

    test('matches by sensor name (case-insensitive)', () {
      provider.setSearchQuery('beta', scope: SensorSearchScope.sensors);
      final results = provider.filteredSensors(scope: SensorSearchScope.sensors);
      expect(results.length, 1);
      expect(results.single.name, 'Beta Monitor');
    });

    test('matches by location', () {
      provider.setSearchQuery('nairobi', scope: SensorSearchScope.sensors);
      expect(
        provider.filteredSensors(scope: SensorSearchScope.sensors).length, 2,
      );
    });

    test('matches by parameter label', () {
      provider.setSearchQuery('turbidity', scope: SensorSearchScope.sensors);
      // AQ-TB-002 has ParameterType.pH by default from makeSensor — override
      provider.setSensorsForTest([
        makeSensor(id: 'AQ-TB-001', param: ParameterType.turbidity),
        makeSensor(id: 'AQ-PH-002', param: ParameterType.pH),
      ]);
      provider.setSearchQuery('turbidity', scope: SensorSearchScope.sensors);

      expect(
        provider.filteredSensors(scope: SensorSearchScope.sensors).length, 1,
      );
    });

    test('empty query returns all sensors', () {
      provider.setSearchQuery('', scope: SensorSearchScope.home);
      expect(provider.filteredSensors(scope: SensorSearchScope.home).length, 3);
    });

    test('clearSearch removes query for that scope only', () {
      provider.setSearchQuery('Alpha', scope: SensorSearchScope.home);
      provider.setSearchQuery('Beta',  scope: SensorSearchScope.sensors);

      provider.clearSearch(scope: SensorSearchScope.home);

      expect(
        provider.filteredSensors(scope: SensorSearchScope.home).length, 3,
        reason: 'clearSearch on home must not affect sensors scope',
      );
      expect(
        provider.filteredSensors(scope: SensorSearchScope.sensors).length, 1,
      );
    });
  });

  // ── recentSensors ─────────────────────────────────────────────────────────

  group('SensorProvider · recentSensors()', () {
    test('returns up to count sensors', () {
      provider.setSensorsForTest(
        List.generate(5, (i) => makeSensor(id: 'AQ-00$i')),
      );
      expect(provider.recentSensors(count: 3).length, 3);
    });

    test('returns all when list is shorter than count', () {
      provider.setSensorsForTest([makeSensor(), makeSensor(id: 'AQ-002')]);
      expect(provider.recentSensors(count: 10).length, 2);
    });
  });

  // ── updateUser guard ──────────────────────────────────────────────────────

  group('SensorProvider · updateUser()', () {
    test('does nothing when userId has not changed', () {
      provider.setSensorsForTest([makeSensor()]);

      // Same null → null, so no reload
      provider.updateUser(null);
      expect(provider.sensors.length, 1,
          reason: 'updateUser with identical userId must not wipe the sensor list');
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Test extension
// ─────────────────────────────────────────────────────────────────────────────

extension SensorProviderTestHelper on SensorProvider {
  void setSensorsForTest(List<SensorModel> sensors) {
    setSensorsForTestInternal(sensors);
  }
}
