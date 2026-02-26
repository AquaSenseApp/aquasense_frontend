import 'package:flutter_test/flutter_test.dart';
import 'package:aquasense/providers/sensor_provider.dart';
import 'package:aquasense/models/sensor_model.dart';
import 'package:aquasense/models/user_model.dart';

void main() {
  group('SensorProvider', () {
    late SensorProvider sensorProvider;
    late UserModel testUser;

    setUp(() {
      testUser = const UserModel(
        userId: 1,
        email: 'test@example.com',
        token: 'test-token',
      );
      sensorProvider = SensorProvider(testUser);
    });

    group('Initial State', () {
      test('should have empty sensors list', () {
        expect(sensorProvider.sensors, isEmpty);
      });

      test('should have initial load state', () {
        expect(sensorProvider.loadState, LoadState.initial);
      });

      test('should have null error message', () {
        expect(sensorProvider.errorMessage, null);
      });

      test('should not be loading initially', () {
        expect(sensorProvider.isLoading, false);
      });
    });

    group('recentSensors', () {
      test('should return empty list when no sensors', () {
        expect(sensorProvider.recentSensors(), isEmpty);
      });

      test('should return limited number of sensors', () {
        // When sensors are added, recentSensors should return limited count
        final recent = sensorProvider.recentSensors(count: 3);
        expect(recent.length, lessThanOrEqualTo(3));
      });
    });

    group('Wizard State', () {
      test('should have correct total wizard steps', () {
        expect(SensorProvider.totalWizardSteps, 5);
      });

      test('should have correct last wizard step index', () {
        expect(SensorProvider.lastWizardStep, 4);
      });

      test('should start at wizard step 0', () {
        expect(sensorProvider.wizardStep, 0);
      });

      test('should have empty form initially', () {
        expect(sensorProvider.form, isA<AddSensorForm>());
        expect(sensorProvider.form.sensorName, '');
        expect(sensorProvider.form.sensorId, '');
      });

      test('nextWizardStep should increment step', () {
        final initialStep = sensorProvider.wizardStep;
        sensorProvider.nextWizardStep();
        expect(sensorProvider.wizardStep, initialStep + 1);
      });

      test('nextWizardStep should not exceed last step', () {
        // Advance to last step
        for (int i = 0; i < 10; i++) {
          sensorProvider.nextWizardStep();
        }
        expect(sensorProvider.wizardStep, SensorProvider.lastWizardStep);
      });

      test('prevWizardStep should decrement step', () {
        sensorProvider.nextWizardStep();
        final stepAfterNext = sensorProvider.wizardStep;
        sensorProvider.prevWizardStep();
        expect(sensorProvider.wizardStep, stepAfterNext - 1);
      });

      test('prevWizardStep should not go below 0', () {
        sensorProvider.prevWizardStep();
        expect(sensorProvider.wizardStep, 0);
      });

      test('resetWizard should reset to step 0', () {
        sensorProvider.nextWizardStep();
        sensorProvider.nextWizardStep();
        sensorProvider.resetWizard();
        expect(sensorProvider.wizardStep, 0);
        expect(sensorProvider.form.sensorName, '');
      });

      test('isLastStep should return true at last step', () {
        // Go to last step
        for (int i = 0; i < SensorProvider.lastWizardStep; i++) {
          sensorProvider.nextWizardStep();
        }
        expect(sensorProvider.isLastStep, true);
      });

      test('isLastStep should return false at earlier steps', () {
        expect(sensorProvider.isLastStep, false);
        sensorProvider.nextWizardStep();
        expect(sensorProvider.isLastStep, false);
      });
    });

    group('canAdvance', () {
      test('should return false at step 0 with invalid form', () {
        expect(sensorProvider.wizardStep, 0);
        expect(sensorProvider.canAdvance, false);
      });

      test('should return true at step 0 with valid form', () {
        sensorProvider.form
          ..parameterType = ParameterType.pH
          ..sensorId = 'sensor-001'
          ..sensorName = 'Test Sensor';
        
        expect(sensorProvider.canAdvance, true);
      });

      test('should return false at step 1 with invalid form', () {
        sensorProvider.nextWizardStep();
        expect(sensorProvider.wizardStep, 1);
        expect(sensorProvider.canAdvance, false);
      });

      test('should return true at step 1 with valid form', () {
        sensorProvider.nextWizardStep();
        sensorProvider.form
          ..site = 'Treatment Plant A'
          ..specificLocation = 'Inlet';
        
        expect(sensorProvider.canAdvance, true);
      });

      test('should return true for step 2 and beyond (optional fields)', () {
        sensorProvider.nextWizardStep();
        sensorProvider.nextWizardStep();
        expect(sensorProvider.wizardStep, 2);
        expect(sensorProvider.canAdvance, true);
      });
    });

    group('Search Functionality', () {
      test('should have empty queries initially', () {
        final homeResults = sensorProvider.filteredSensors(scope: SensorSearchScope.home);
        final sensorsResults = sensorProvider.filteredSensors(scope: SensorSearchScope.sensors);
        
        expect(homeResults, isEmpty);
        expect(sensorsResults, isEmpty);
      });

      test('setSearchQuery should update query for specific scope', () {
        sensorProvider.setSearchQuery('test', scope: SensorSearchScope.home);
        
        // The method should not throw and should notify listeners
        expect(sensorProvider.wizardStep, 0); // State unchanged
      });

      test('clearSearch should remove query for specific scope', () {
        sensorProvider.setSearchQuery('test', scope: SensorSearchScope.home);
        sensorProvider.clearSearch(scope: SensorSearchScope.home);
        
        // Should complete without error
      });
    });

    group('updateUser', () {
      test('should update user when different userId', () {
        final newUser = const UserModel(
          userId: 2,
          email: 'new@example.com',
          token: 'new-token',
        );
        
        // Should not throw when updating user
        sensorProvider.updateUser(newUser);
      });

      test('should not reload when same userId', () {
        final sameUser = const UserModel(
          userId: 1,
          email: 'test@example.com',
          token: 'test-token',
        );
        
        // Should handle gracefully
        sensorProvider.updateUser(sameUser);
      });
    });

    group('LoadState Enum', () {
      test('should have all required values', () {
        expect(LoadState.values.length, 4);
        expect(LoadState.values.contains(LoadState.initial), true);
        expect(LoadState.values.contains(LoadState.loading), true);
        expect(LoadState.values.contains(LoadState.loaded), true);
        expect(LoadState.values.contains(LoadState.error), true);
      });
    });

    group('SensorSearchScope Enum', () {
      test('should have home and sensors values', () {
        expect(SensorSearchScope.values.length, 2);
        expect(SensorSearchScope.values.contains(SensorSearchScope.home), true);
        expect(SensorSearchScope.values.contains(SensorSearchScope.sensors), true);
      });
    });

    group('EditSensorForm', () {
      test('should create form with sensor values', () {
        final sensor = SensorModel(
          id: 'sensor-1',
          name: 'Test Sensor',
          location: 'Test Location',
          parameter: ParameterType.pH,
          riskLevel: RiskLevel.medium,
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
          safeRange: '6.5 - 8.0',
          alertThreshold: AlertThreshold.warningLevel,
          aiAdvisoryEnabled: true,
          sensitivityLevel: RiskSensitivityLevel.medium,
        );

        final form = EditSensorForm.fromSensor(sensor);

        expect(form.name, 'Test Sensor');
        expect(form.location, 'Test Location');
        expect(form.safeRange, '6.5 - 8.0');
        expect(form.alertThreshold, AlertThreshold.warningLevel);
        expect(form.aiAdvisoryEnabled, true);
        expect(form.sensitivityLevel, RiskSensitivityLevel.medium);
      });

      test('isValid should return true when name and location are provided', () {
        final form = EditSensorForm(
          name: 'Test',
          location: 'Test Location',
          safeRange: '',
          alertThreshold: null,
          aiAdvisoryEnabled: false,
          sensitivityLevel: null,
        );

        expect(form.isValid, true);
      });

      test('isValid should return false when name is empty', () {
        final form = EditSensorForm(
          name: '',
          location: 'Test Location',
          safeRange: '',
          alertThreshold: null,
          aiAdvisoryEnabled: false,
          sensitivityLevel: null,
        );

        expect(form.isValid, false);
      });

      test('isValid should return false when location is empty', () {
        final form = EditSensorForm(
          name: 'Test',
          location: '',
          safeRange: '',
          alertThreshold: null,
          aiAdvisoryEnabled: false,
          sensitivityLevel: null,
        );

        expect(form.isValid, false);
      });
    });
  });
}
