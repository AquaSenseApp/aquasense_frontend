// test/unit/services/api_endpoints_test.dart
//
// WHY these tests exist
// ─────────────────────
// Every service class calls ApiEndpoints to get a path string.  If a method
// builds the wrong URL — e.g. /api/alerts/users/1 instead of
// /api/alerts/user/1 — every call silently returns 404 and the user sees
// a blank alerts screen.  Pinning URLs here means a typo fails CI loudly
// rather than failing silently at the user's device.
//
// We also enforce that no raw URL strings appear in service files by testing
// that the constants match the backend contract documented in the API spec.

import 'package:flutter_test/flutter_test.dart';
import 'package:aquasense/core/network/api_endpoints.dart';

void main() {
  // ── Static constants ──────────────────────────────────────────────────────

  group('ApiEndpoints · static constants', () {
    test('login path matches backend route', () {
      expect(ApiEndpoints.login, '/api/users/login');
    });

    test('register path matches backend route', () {
      expect(ApiEndpoints.register, '/api/users/register');
    });

    test('registerSensor path matches backend route', () {
      expect(ApiEndpoints.registerSensor, '/api/sensors/register');
    });

    test('uploadReading path matches backend route', () {
      expect(ApiEndpoints.uploadReading, '/api/readings/upload');
    });

    test('baseUrl does not end with a slash — Dio appends paths starting with /', () {
      expect(ApiEndpoints.baseUrl.endsWith('/'), isFalse,
          reason: 'A trailing slash on baseUrl + a leading slash on path '
              'produces a double-slash URL that breaks the backend router');
    });

    test('all static paths start with a leading slash', () {
      for (final path in [
        ApiEndpoints.login,
        ApiEndpoints.register,
        ApiEndpoints.registerSensor,
        ApiEndpoints.uploadReading,
      ]) {
        expect(path.startsWith('/'), isTrue,
            reason: '"$path" must start with "/" to be resolved against baseUrl');
      }
    });
  });

  // ── Parameterised path builders ───────────────────────────────────────────

  group('ApiEndpoints · sensorsByUser()', () {
    test('builds the correct path for userId=1', () {
      expect(ApiEndpoints.sensorsByUser(1), '/api/sensors/user/1');
    });

    test('builds the correct path for a large userId', () {
      expect(ApiEndpoints.sensorsByUser(99999), '/api/sensors/user/99999');
    });

    test('interpolates the userId — not a hardcoded "1"', () {
      // If someone accidentally hardcodes the ID, different values must differ
      expect(
        ApiEndpoints.sensorsByUser(2),
        isNot(equals(ApiEndpoints.sensorsByUser(3))),
      );
    });
  });

  group('ApiEndpoints · analyticsForUser()', () {
    test('builds the correct path for userId=1', () {
      expect(ApiEndpoints.analyticsForUser(1), '/api/sensors/analytics/1');
    });

    test('builds distinct paths for distinct user IDs', () {
      expect(
        ApiEndpoints.analyticsForUser(1),
        isNot(equals(ApiEndpoints.analyticsForUser(2))),
      );
    });
  });

  group('ApiEndpoints · alertsByUser()', () {
    test('builds the correct path for userId=1', () {
      expect(ApiEndpoints.alertsByUser(1), '/api/alerts/user/1');
    });

    test('note: "user" singular — matches backend route (not "users")', () {
      // WHY test this specific string?  We previously had a bug where
      // "users" (plural) was used, returning 404 on every alerts fetch.
      expect(ApiEndpoints.alertsByUser(1), contains('/user/'));
      expect(ApiEndpoints.alertsByUser(1), isNot(contains('/users/')));
    });
  });

  group('ApiEndpoints · resolveAlert()', () {
    test('builds the correct path for alertId=1', () {
      expect(ApiEndpoints.resolveAlert(1), '/api/alerts/resolve/1');
    });

    test('builds distinct paths for distinct alert IDs', () {
      expect(
        ApiEndpoints.resolveAlert(1),
        isNot(equals(ApiEndpoints.resolveAlert(2))),
      );
    });
  });
}
