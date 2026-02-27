import 'package:flutter_test/flutter_test.dart';
import 'package:aquasense/models/alert_model.dart';

void main() {
  group('AlertType', () {
    test('label returns correct string for each enum value', () {
      expect(AlertType.alert.label, 'Alert');
      expect(AlertType.recommendation.label, 'Recommendation');
      expect(AlertType.anomaly.label, 'AI Anomaly');
      expect(AlertType.compliance.label, 'Compliance');
    });
  });

  group('AlertModel', () {
    test('should create AlertModel with required fields', () {
      final alert = AlertModel(
        id: '1',
        title: 'Test Alert',
        description: 'Test Description',
        reading: '7.2 pH',
        safeRange: '6.5 - 8.5',
        type: AlertType.alert,
        timestamp: DateTime(2024, 1, 1),
      );

      expect(alert.id, '1');
      expect(alert.title, 'Test Alert');
      expect(alert.description, 'Test Description');
      expect(alert.reading, '7.2 pH');
      expect(alert.safeRange, '6.5 - 8.5');
      expect(alert.type, AlertType.alert);
      expect(alert.timestamp, DateTime(2024, 1, 1));
    });

    test('should use default status as active', () {
      final alert = AlertModel(
        id: '1',
        title: 'Test Alert',
        description: 'Test Description',
        reading: '',
        safeRange: '',
        type: AlertType.alert,
        timestamp: DateTime(2024, 1, 1),
      );

      expect(alert.status, 'active');
      expect(alert.isActive, true);
      expect(alert.isResolved, false);
    });

    test('isActive returns true when status is active', () {
      final alert = AlertModel(
        id: '1',
        title: 'Test Alert',
        description: 'Test Description',
        reading: '',
        safeRange: '',
        type: AlertType.alert,
        status: 'active',
        timestamp: DateTime(2024, 1, 1),
      );

      expect(alert.isActive, true);
      expect(alert.isResolved, false);
    });

    test('isResolved returns true when status is resolved', () {
      final alert = AlertModel(
        id: '1',
        title: 'Test Alert',
        description: 'Test Description',
        reading: '',
        safeRange: '',
        type: AlertType.alert,
        status: 'resolved',
        timestamp: DateTime(2024, 1, 1),
      );

      expect(alert.isActive, false);
      expect(alert.isResolved, true);
    });

    test('readingLine returns formatted string with reading and safe range', () {
      final alert = AlertModel(
        id: '1',
        title: 'Test Alert',
        description: 'Test Description',
        reading: '7.2 pH',
        safeRange: '6.5 - 8.5',
        type: AlertType.alert,
        timestamp: DateTime(2024, 1, 1),
      );

      expect(alert.readingLine, '7.2 pH | Safe: 6.5 - 8.5');
    });

    test('readingLine returns description when reading and safeRange are empty', () {
      final alert = AlertModel(
        id: '1',
        title: 'Test Alert',
        description: 'Test Description',
        reading: '',
        safeRange: '',
        type: AlertType.alert,
        timestamp: DateTime(2024, 1, 1),
      );

      expect(alert.readingLine, 'Test Description');
    });

    test('copyWith creates new instance with updated status', () {
      final original = AlertModel(
        id: '1',
        title: 'Test Alert',
        description: 'Test Description',
        reading: '7.2 pH',
        safeRange: '6.5 - 8.5',
        type: AlertType.alert,
        status: 'active',
        timestamp: DateTime(2024, 1, 1),
      );

      final resolved = original.copyWith(status: 'resolved');

      expect(original.status, 'active');
      expect(resolved.status, 'resolved');
      expect(resolved.id, original.id);
      expect(resolved.title, original.title);
    });
  });

  group('AlertFilter', () {
    test('label returns correct string for each enum value', () {
      expect(AlertFilter.all.label, 'All');
      expect(AlertFilter.alerts.label, 'Alerts');
      expect(AlertFilter.recommendation.label, 'Recommendation');
    });

    test('matches returns true for all types when filter is all', () {
      expect(AlertFilter.all.matches(AlertType.alert), true);
      expect(AlertFilter.all.matches(AlertType.recommendation), true);
      expect(AlertFilter.all.matches(AlertType.anomaly), true);
      expect(AlertFilter.all.matches(AlertType.compliance), true);
    });

    test('matches returns true for alert types when filter is alerts', () {
      expect(AlertFilter.alerts.matches(AlertType.alert), true);
      expect(AlertFilter.alerts.matches(AlertType.anomaly), true);
      expect(AlertFilter.alerts.matches(AlertType.compliance), true);
      expect(AlertFilter.alerts.matches(AlertType.recommendation), false);
    });

    test('matches returns true only for recommendation when filter is recommendation', () {
      expect(AlertFilter.recommendation.matches(AlertType.recommendation), true);
      expect(AlertFilter.recommendation.matches(AlertType.alert), false);
      expect(AlertFilter.recommendation.matches(AlertType.anomaly), false);
      expect(AlertFilter.recommendation.matches(AlertType.compliance), false);
    });
  });
}
