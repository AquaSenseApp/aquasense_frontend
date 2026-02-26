// test/unit/providers/alert_provider_test.dart
//
// WHY these tests exist
// ─────────────────────
// AlertProvider.visibleAlerts and groupedAlerts contain real business logic.
// groupedAlerts decides whether an alert appears under "Today" or "Yesterday".
// An off-by-one in the date diff means an operator thinks a warning arrived
// today when it arrived 25 hours ago — materially misleading in a safety context.

import 'package:flutter_test/flutter_test.dart';
import 'package:aquasense/models/alert_model.dart';
import 'package:aquasense/providers/alert_provider.dart';
import '../../helpers/test_helpers.dart';

void main() {
  late AlertProvider provider;

  setUp(() {
    setupFakeSharedPrefs();
    // Pass null user so loadAlerts() does not fire in setUp — we seed manually.
    provider = AlertProvider(null);
  });

  // ── setFilter ─────────────────────────────────────────────────────────────

  group('AlertProvider · setFilter()', () {
    setUp(() {
      provider.setAlertsForTest([
        makeAlert(id: '1', type: AlertType.alert),
        makeAlert(id: '2', type: AlertType.recommendation),
        makeAlert(id: '3', type: AlertType.anomaly),
        makeAlert(id: '4', type: AlertType.compliance),
      ]);
    });

    test('AlertFilter.all shows all 4 alerts', () {
      provider.setFilter(AlertFilter.all);
      expect(provider.visibleAlerts.length, 4);
    });

    test('AlertFilter.alerts shows 3 (alert + anomaly + compliance)', () {
      provider.setFilter(AlertFilter.alerts);
      expect(provider.visibleAlerts.length, 3);
      expect(
        provider.visibleAlerts.map((a) => a.type),
        isNot(contains(AlertType.recommendation)),
      );
    });

    test('AlertFilter.recommendation shows only 1', () {
      provider.setFilter(AlertFilter.recommendation);
      expect(provider.visibleAlerts.length, 1);
      expect(provider.visibleAlerts.single.type, AlertType.recommendation);
    });

    test('setFilter notifies listeners', () {
      var notified = false;
      provider.addListener(() => notified = true);
      provider.setFilter(AlertFilter.alerts);
      expect(notified, isTrue);
    });
  });

  // ── search ────────────────────────────────────────────────────────────────

  group('AlertProvider · search', () {
    setUp(() {
      provider.setAlertsForTest([
        makeAlert(id: '1', title: 'pH is low',       desc: 'Advisory: treat water'),
        makeAlert(id: '2', title: 'Turbidity spike', desc: 'Run coagulation cycle'),
        makeAlert(id: '3', title: 'Oxygen normal',   desc: 'No action required'),
      ]);
    });

    test('matches by title (case-insensitive)', () {
      provider.setSearchQuery('ph');
      expect(provider.visibleAlerts.length, 1);
      expect(provider.visibleAlerts.single.id, '1');
    });

    test('matches by description', () {
      provider.setSearchQuery('coagulation');
      expect(provider.visibleAlerts.length, 1);
      expect(provider.visibleAlerts.single.id, '2');
    });

    test('empty query shows all alerts', () {
      provider.setSearchQuery('');
      expect(provider.visibleAlerts.length, 3);
    });

    test('unmatched query returns empty list', () {
      provider.setSearchQuery('zzz-nomatch-zzz');
      expect(provider.visibleAlerts, isEmpty);
    });

    test('clearSearch restores full list', () {
      provider.setSearchQuery('ph');
      provider.clearSearch();
      expect(provider.visibleAlerts.length, 3);
    });
  });

  // ── filter + search combined ──────────────────────────────────────────────

  group('AlertProvider · filter AND search combined', () {
    setUp(() {
      provider.setAlertsForTest([
        makeAlert(id: '1', type: AlertType.alert,          title: 'pH critical'),
        makeAlert(id: '2', type: AlertType.recommendation, title: 'pH advisory'),
        makeAlert(id: '3', type: AlertType.alert,          title: 'Turbidity high'),
      ]);
    });

    test('shows only alerts matching both filter and query', () {
      provider.setFilter(AlertFilter.alerts);
      provider.setSearchQuery('ph');

      expect(provider.visibleAlerts.length, 1);
      expect(provider.visibleAlerts.single.id, '1');
    });
  });

  // ── groupedAlerts ─────────────────────────────────────────────────────────

  group('AlertProvider · groupedAlerts', () {
    test('returns empty list when no alerts exist', () {
      expect(provider.groupedAlerts, isEmpty);
    });

    test('places today\'s alerts under a "Today" label', () {
      final now = DateTime.now();
      provider.setAlertsForTest([
        alertAt(makeAlert(id: '1'), now),
        alertAt(makeAlert(id: '2'), now.subtract(const Duration(hours: 3))),
      ]);

      final groups = provider.groupedAlerts;
      expect(groups.length, 1);
      expect(groups.first.label, startsWith('Today'));
      expect(groups.first.alerts.length, 2);
    });

    test('separates today and yesterday into two distinct groups', () {
      final now       = DateTime.now();
      final yesterday = now.subtract(const Duration(hours: 25));

      provider.setAlertsForTest([
        alertAt(makeAlert(id: '1'), now),
        alertAt(makeAlert(id: '2'), yesterday),
      ]);

      final groups  = provider.groupedAlerts;
      final labels  = groups.map((g) => g.label).toList();

      expect(groups.length, 2);
      expect(labels.any((l) => l.startsWith('Today')),     isTrue);
      expect(labels.any((l) => l.startsWith('Yesterday')), isTrue);
    });

    test('uses month name in date label — e.g. "Feb 24"', () {
      final feb24 = DateTime(2026, 2, 24, 10);
      provider.setAlertsForTest([alertAt(makeAlert(), feb24)]);

      final groups = provider.groupedAlerts;
      // Label will be "Today, Feb 24" or "Feb 24" depending on test run date
      expect(groups.first.label, contains('Feb'));
      expect(groups.first.label, contains('24'));
    });
  });

  // ── resolveAlert (local) ──────────────────────────────────────────────────

  group('AlertProvider · resolveAlert() — local toggle (no apiId)', () {
    test('toggles status from active to resolved', () async {
      final alert = makeAlert(id: 'local-1', apiId: null, status: 'active');
      provider.setAlertsForTest([alert]);

      final result = await provider.resolveAlert(alert);

      expect(result, isTrue);
      expect(provider.visibleAlerts.single.isResolved, isTrue);
    });

    test('notifies listeners after local resolve', () async {
      final alert = makeAlert(id: 'local-2', apiId: null);
      provider.setAlertsForTest([alert]);

      var notified = false;
      provider.addListener(() => notified = true);

      await provider.resolveAlert(alert);
      expect(notified, isTrue);
    });
  });

  // ── updateUser ────────────────────────────────────────────────────────────

  group('AlertProvider · updateUser()', () {
    test('does nothing when userId has not changed', () {
      provider.setAlertsForTest([makeAlert()]);

      // Calling updateUser with the same null user must not wipe the alerts
      provider.updateUser(null);
      expect(provider.visibleAlerts.length, 1);
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Test extension — calls the @visibleForTesting seeder
// ─────────────────────────────────────────────────────────────────────────────

extension AlertProviderTestHelper on AlertProvider {
  void setAlertsForTest(List<AlertModel> alerts) {
    // Delegates to the @visibleForTesting method declared in the provider.
    // Keeping the call in an extension here means test files never import
    // the provider's internal method directly — one call-site to update.
    setAlertsForTestInternal(alerts);
  }
}
