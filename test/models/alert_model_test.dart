import 'package:flutter_test/flutter_test.dart';
import 'package:aquasense/models/alert_model.dart';

void main() {
  group('AlertType', () {
    test('should return correct label for alert', () {
      expect(AlertType.alert.label, 'Alert');
    });

    test('should return correct label for recommendation', () {
      expect(AlertType.recommendation.label, 'Recommendation');
    });

    test('should return correct label for anomaly', () {
      expect(AlertType.anomaly.label, 'AI Anomaly');
    });

    test('should return correct label for compliance', () {
      expect(AlertType.compliance.label, 'Compliance');
    });
  });

  group('AlertModel', () {
    late AlertModel alert;

    setUp(() {
      alert = AlertModel(
        id: 'alert-123',
        apiId: 123,
        title: 'pH Level Warning',
        description: 'The pH level has exceeded the warning threshold',
        reading: '9.2 pH',
        safeRange: '6.5 - 8.0',
        type: AlertType.alert,
        status: 'active',
        timestamp: DateTime(2024, 1, 15, 10, 30),
      );
    });

    test('should create AlertModel with all parameters', () {
      expect(alert.id, 'alert-123');
      expect(alert.apiId, 123);
      expect(alert.title, 'pH Level Warning');
      expect(alert.description, 'The pH level has exceeded the warning threshold');
      expect(alert.reading, '9.2 pH');
      expect(alert.safeRange, '6.5 - 8.0');
      expect(alert.type, AlertType.alert);
      expect(alert.status, 'active');
      expect(alert.timestamp, DateTime(2024, 1, 15, 10, 30));
    });

    test('should create AlertModel with default status', () {
      final defaultAlert = AlertModel(
        id: 'alert-456',
        title: 'Test Alert',
        description: 'Test Description',
        reading: '7.0 pH',
        safeRange: '6.5 - 8.0',
        type: AlertType.alert,
        timestamp: DateTime(2024, 1, 15),
      );

      expect(defaultAlert.status, 'active');
    });

    test('isActive should return true for active status', () {
      expect(alert.isActive, true);
      expect(alert.isResolved, false);
    });

    test('isResolved should return true for resolved status', () {
      final resolvedAlert = alert.copyWith(status: 'resolved');

      expect(resolvedAlert.isActive, false);
      expect(resolvedAlert.isResolved, true);
    });

    test('readingLine should combine reading and safe range', () {
      expect(alert.readingLine, '9.2 pH | Safe: 6.5 - 8.0');
    });

    test('readingLine should return description when reading and safeRange are empty', () {
      final emptyAlert = AlertModel(
        id: 'alert-789',
        title: 'Test',
        description: 'Test description only',
        reading: '',
        safeRange: '',
        type: AlertType.alert,
        timestamp: DateTime(2024, 1, 15),
      );

      expect(emptyAlert.readingLine, 'Test description only');
    });

    test('copyWith should create new instance with updated status', () {
      final updated = alert.copyWith(status: 'resolved');

      expect(updated.id, alert.id);
      expect(updated.apiId, alert.apiId);
      expect(updated.title, alert.title);
      expect(updated.status, 'resolved');
    });

    test('copyWith should preserve all other values', () {
      final updated = alert.copyWith(status: 'resolved');

      expect(updated.title, alert.title);
      expect(updated.description, alert.description);
      expect(updated.reading, alert.reading);
      expect(updated.safeRange, alert.safeRange);
      expect(updated.type, alert.type);
      expect(updated.timestamp, alert.timestamp);
    });
  });

  group('AlertFilter', () {
    test('should return correct label for all', () {
      expect(AlertFilter.all.label, 'All');
    });

    test('should return correct label for alerts', () {
      expect(AlertFilter.alerts.label, 'Alerts');
    });

    test('should return correct label for recommendation', () {
      expect(AlertFilter.recommendation.label, 'Recommendation');
    });

    group('matches', () {
      test('all filter should match all types', () {
        final filter = AlertFilter.all;

        expect(filter.matches(AlertType.alert), true);
        expect(filter.matches(AlertType.recommendation), true);
        expect(filter.matches(AlertType.anomaly), true);
        expect(filter.matches(AlertType.compliance), true);
      });

      test('alerts filter should match alert, anomaly, and compliance', () {
        final filter = AlertFilter.alerts;

        expect(filter.matches(AlertType.alert), true);
        expect(filter.matches(AlertType.anomaly), true);
        expect(filter.matches(AlertType.compliance), true);
        expect(filter.matches(AlertType.recommendation), false);
      });

      test('recommendation filter should only match recommendation', () {
        final filter = AlertFilter.recommendation;

        expect(filter.matches(AlertType.recommendation), true);
        expect(filter.matches(AlertType.alert), false);
        expect(filter.matches(AlertType.anomaly), false);
        expect(filter.matches(AlertType.compliance), false);
      });
    });
  });

  group('AlertModel factory scenarios', () {
    test('should handle all alert types correctly', () {
      final alertTypes = [
        AlertType.alert,
        AlertType.recommendation,
        AlertType.anomaly,
        AlertType.compliance,
      ];

      for (final type in alertTypes) {
        final alert = AlertModel(
          id: 'test-${type.name}',
          title: 'Test ${type.label}',
          description: 'Test description',
          reading: '7.0 pH',
          safeRange: '6.5 - 8.0',
          type: type,
          timestamp: DateTime.now(),
        );

        expect(alert.type, type);
        expect(alert.isActive, true);
      }
    });

    test('should handle various timestamp formats', () {
      final timestamps = [
        DateTime(2024, 1, 1, 0, 0),
        DateTime(2024, 12, 31, 23, 59, 59),
        DateTime(2024, 6, 15, 12, 30, 45),
      ];

      for (final timestamp in timestamps) {
        final alert = AlertModel(
          id: 'timestamp-test',
          title: 'Test',
          description: 'Test',
          reading: '',
          safeRange: '',
          type: AlertType.alert,
          timestamp: timestamp,
        );

        expect(alert.timestamp, timestamp);
      }
    });

    test('should handle null apiId for locally created alerts', () {
      final localAlert = AlertModel(
        id: 'local-alert-123',
        title: 'Local Alert',
        description: 'Created locally',
        reading: '7.5 pH',
        safeRange: '6.5 - 8.0',
        type: AlertType.recommendation,
        timestamp: DateTime.now(),
      );

      expect(localAlert.apiId, null);
      expect(localAlert.id.startsWith('local-alert'), true);
    });
  });
}
