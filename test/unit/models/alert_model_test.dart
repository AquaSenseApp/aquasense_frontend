// test/unit/models/alert_model_test.dart
//
// WHY these tests exist
// ─────────────────────
// AlertFilter.matches() decides which alerts an operator sees in each tab.
// A wrong implementation means a critical pH warning disappears from the
// "Alerts" tab — a safety issue, not just a UI glitch.  We test every
// (filter, type) combination so the truth table is explicit and auditable.

import 'package:flutter_test/flutter_test.dart';
import 'package:aquasense/models/alert_model.dart';
import '../../helpers/test_helpers.dart';

void main() {
  // ── AlertModel computed properties ───────────────────────────────────────

  group('AlertModel · status helpers', () {
    test('isActive is true for "active" status', () {
      expect(makeAlert(status: 'active').isActive,   isTrue);
      expect(makeAlert(status: 'active').isResolved, isFalse);
    });

    test('isResolved is true for "resolved" status', () {
      expect(makeAlert(status: 'resolved').isResolved, isTrue);
      expect(makeAlert(status: 'resolved').isActive,   isFalse);
    });
  });

  group('AlertModel · readingLine', () {
    test('combines reading and safeRange with pipe separator', () {
      final line = makeAlert().readingLine;
      expect(line, contains('|'));
      expect(line, contains('Safe:'));
    });

    test('falls back to description when reading and safeRange are both empty', () {
      final alert = AlertModel(
        id: 'x', title: 'T', description: 'Fallback text',
        reading: '', safeRange: '', type: AlertType.alert,
        timestamp: DateTime(2026),
      );
      expect(alert.readingLine, 'Fallback text');
    });
  });

  group('AlertModel · copyWith', () {
    test('changes only status, preserves every other field', () {
      final resolved = makeAlert(status: 'active').copyWith(status: 'resolved');
      expect(resolved.status, 'resolved');
      expect(resolved.title,  makeAlert().title);
    });
  });

  // ── AlertFilter truth table ───────────────────────────────────────────────
  // Every cell in the (filter × type) matrix is explicit here.
  // We chose a parameterised-style loop for AlertFilter.all because
  // "all means all" — if you add a new AlertType, the test catches it.

  group('AlertFilter.all', () {
    for (final type in AlertType.values) {
      test('shows ${type.name}', () {
        expect(AlertFilter.all.matches(type), isTrue);
      });
    }
  });

  group('AlertFilter.alerts', () {
    test('shows alert',      () => expect(AlertFilter.alerts.matches(AlertType.alert),      isTrue));
    test('shows anomaly',    () => expect(AlertFilter.alerts.matches(AlertType.anomaly),    isTrue));
    test('shows compliance', () => expect(AlertFilter.alerts.matches(AlertType.compliance), isTrue));
    test('hides recommendation — belongs in its own tab', () {
      expect(AlertFilter.alerts.matches(AlertType.recommendation), isFalse);
    });
  });

  group('AlertFilter.recommendation', () {
    test('shows recommendation', () =>
        expect(AlertFilter.recommendation.matches(AlertType.recommendation), isTrue));
    test('hides alert',      () => expect(AlertFilter.recommendation.matches(AlertType.alert),      isFalse));
    test('hides anomaly',    () => expect(AlertFilter.recommendation.matches(AlertType.anomaly),    isFalse));
    test('hides compliance', () => expect(AlertFilter.recommendation.matches(AlertType.compliance), isFalse));
  });
}
