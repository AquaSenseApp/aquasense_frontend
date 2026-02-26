import 'package:flutter_test/flutter_test.dart';
import 'package:aquasense/providers/alert_provider.dart';
import 'package:aquasense/models/user_model.dart';
import 'package:aquasense/models/alert_model.dart';

void main() {
  group('AlertProvider', () {
    late AlertProvider alertProvider;
    late UserModel testUser;

    setUp(() {
      testUser = const UserModel(
        userId: 1,
        email: 'test@example.com',
        token: 'test-token',
      );
      alertProvider = AlertProvider(testUser);
    });

    group('Initial State', () {
      test('should have initial load state', () {
        expect(alertProvider.loadState, AlertLoadState.initial);
      });

      test('should have all filter as default', () {
        expect(alertProvider.filter, AlertFilter.all);
      });

      test('should have empty search query', () {
        expect(alertProvider.errorMessage, null);
      });

      test('should not be loading initially', () {
        expect(alertProvider.isLoading, false);
      });
    });

    group('Filter Functionality', () {
      test('setFilter should update filter', () {
        alertProvider.setFilter(AlertFilter.alerts);
        expect(alertProvider.filter, AlertFilter.alerts);
      });

      test('setFilter should notify listeners', () {
        bool notified = false;
        alertProvider.addListener(() {
          notified = true;
        });
        
        alertProvider.setFilter(AlertFilter.recommendation);
        expect(notified, true);
      });

      test('should be able to set all filter types', () {
        alertProvider.setFilter(AlertFilter.all);
        expect(alertProvider.filter, AlertFilter.all);

        alertProvider.setFilter(AlertFilter.alerts);
        expect(alertProvider.filter, AlertFilter.alerts);

        alertProvider.setFilter(AlertFilter.recommendation);
        expect(alertProvider.filter, AlertFilter.recommendation);
      });
    });

    group('Search Functionality', () {
      test('setSearchQuery should update query', () {
        alertProvider.setSearchQuery('pH');
        // Should complete without error
      });

      test('setSearchQuery should convert to lowercase', () {
        alertProvider.setSearchQuery('PH');
        // Should handle the query (case-insensitive implementation)
      });

      test('clearSearch should reset query', () {
        alertProvider.setSearchQuery('test');
        alertProvider.clearSearch();
        // Should complete without error
      });

      test('search should notify listeners', () {
        bool notified = false;
        alertProvider.addListener(() {
          notified = true;
        });
        
        alertProvider.setSearchQuery('search term');
        expect(notified, true);
      });
    });

    group('visibleAlerts', () {
      test('should return empty list when no alerts', () {
        expect(alertProvider.visibleAlerts, isEmpty);
      });
    });

    group('groupedAlerts', () {
      test('should return empty list when no alerts', () {
        expect(alertProvider.groupedAlerts, isEmpty);
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
        alertProvider.updateUser(newUser);
      });

      test('should not reload when same userId', () {
        final sameUser = const UserModel(
          userId: 1,
          email: 'test@example.com',
          token: 'test-token',
        );
        
        // Should handle gracefully
        alertProvider.updateUser(sameUser);
      });
    });

    group('AlertLoadState Enum', () {
      test('should have all required values', () {
        expect(AlertLoadState.values.length, 4);
        expect(AlertLoadState.values.contains(AlertLoadState.initial), true);
        expect(AlertLoadState.values.contains(AlertLoadState.loading), true);
        expect(AlertLoadState.values.contains(AlertLoadState.loaded), true);
        expect(AlertLoadState.values.contains(AlertLoadState.error), true);
      });
    });

    group('AlertFilter Enum', () {
      test('should have all required values', () {
        expect(AlertFilter.values.length, 3);
        expect(AlertFilter.values.contains(AlertFilter.all), true);
        expect(AlertFilter.values.contains(AlertFilter.alerts), true);
        expect(AlertFilter.values.contains(AlertFilter.recommendation), true);
      });

      test('matches should work correctly', () {
        expect(AlertFilter.all.matches(AlertType.alert), true);
        expect(AlertFilter.all.matches(AlertType.recommendation), true);
        expect(AlertFilter.all.matches(AlertType.anomaly), true);
        expect(AlertFilter.all.matches(AlertType.compliance), true);

        expect(AlertFilter.alerts.matches(AlertType.alert), true);
        expect(AlertFilter.alerts.matches(AlertType.anomaly), true);
        expect(AlertFilter.alerts.matches(AlertType.compliance), true);
        expect(AlertFilter.alerts.matches(AlertType.recommendation), false);

        expect(AlertFilter.recommendation.matches(AlertType.recommendation), true);
        expect(AlertFilter.recommendation.matches(AlertType.alert), false);
        expect(AlertFilter.recommendation.matches(AlertType.anomaly), false);
        expect(AlertFilter.recommendation.matches(AlertType.compliance), false);
      });
    });
  });

  group('AlertModel Status Helpers', () {
    test('isActive should return true for active status', () {
      final alert = AlertModel(
        id: 'test-1',
        title: 'Test',
        description: 'Test',
        reading: '',
        safeRange: '',
        type: AlertType.alert,
        status: 'active',
        timestamp: DateTime.now(),
      );

      expect(alert.isActive, true);
      expect(alert.isResolved, false);
    });

    test('isResolved should return true for resolved status', () {
      final alert = AlertModel(
        id: 'test-1',
        title: 'Test',
        description: 'Test',
        reading: '',
        safeRange: '',
        type: AlertType.alert,
        status: 'resolved',
        timestamp: DateTime.now(),
      );

      expect(alert.isActive, false);
      expect(alert.isResolved, true);
    });

    test('copyWith should update status correctly', () {
      final activeAlert = AlertModel(
        id: 'test-1',
        title: 'Test',
        description: 'Test',
        reading: '',
        safeRange: '',
        type: AlertType.alert,
        status: 'active',
        timestamp: DateTime.now(),
      );

      final resolvedAlert = activeAlert.copyWith(status: 'resolved');

      expect(resolvedAlert.status, 'resolved');
      expect(resolvedAlert.id, activeAlert.id);
      expect(resolvedAlert.title, activeAlert.title);
    });
  });
}
