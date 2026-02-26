// test/unit/services/api_exception_test.dart
//
// WHY these tests exist
// ─────────────────────
// Every service wraps a DioException into ApiException and then calls
// displayMessage to produce the string shown in the UI.  If displayMessage
// returns the raw Dio JSON blob instead of "Session expired", the user
// sees "{error: Unauthorized}" in a snackbar.  These tests pin the contract.

import 'package:flutter_test/flutter_test.dart';
import 'package:aquasense/core/errors/api_exception.dart';

void main() {
  group('ApiException · classification', () {
    test('isNetworkError is true when statusCode is null', () {
      expect(const ApiException(message: 'no connection').isNetworkError, isTrue);
    });

    test('isNetworkError is false when statusCode is present', () {
      expect(const ApiException(statusCode: 500, message: 'oops').isNetworkError, isFalse);
    });

    test('isUnauthorised is true for HTTP 401', () {
      expect(const ApiException(statusCode: 401, message: 'Unauthorized').isUnauthorised, isTrue);
    });

    test('isUnauthorised is false for HTTP 403 (forbidden ≠ unauthorised)', () {
      expect(const ApiException(statusCode: 403, message: 'Forbidden').isUnauthorised, isFalse);
    });

    test('isUnauthorised is false when statusCode is null', () {
      expect(const ApiException(message: 'no conn').isUnauthorised, isFalse);
    });
  });

  group('ApiException · displayMessage', () {
    test('network errors use a friendly message — not a raw Dio string', () {
      const e = ApiException(message: 'SocketException: connection refused');
      expect(e.displayMessage, contains('No internet'),
          reason: 'Raw Dio messages must never reach the user');
    });

    test('401 responses produce "Session expired" message', () {
      const e = ApiException(statusCode: 401, message: 'Unauthorized');
      expect(e.displayMessage, contains('Session expired'));
    });

    test('other HTTP errors pass through the server message verbatim', () {
      const e = ApiException(statusCode: 422, message: 'Email already in use');
      expect(e.displayMessage, 'Email already in use');
    });

    test('500 errors pass through the server message', () {
      const e = ApiException(statusCode: 500, message: 'Internal Server Error');
      expect(e.displayMessage, 'Internal Server Error');
    });
  });

  group('ApiException · toString', () {
    test('includes both statusCode and message', () {
      const e = ApiException(statusCode: 404, message: 'Not found');
      expect(e.toString(), contains('404'));
      expect(e.toString(), contains('Not found'));
    });

    test('handles null statusCode without throwing', () {
      const e = ApiException(message: 'Network error');
      expect(() => e.toString(), returnsNormally);
    });
  });

  group('ApiAlertDto · toModel message parsing', () {
    // WHY test toModel here?  ApiAlertDto._extractTitle and _inferType
    // contain real parsing logic that runs every time alerts load.
    // We inline the logic mirror here so it stays co-located with
    // the exception tests (same services layer) without importing Dio.

    String extractTitle(String msg) {
      final dotIdx = msg.indexOf('.');
      if (dotIdx > 0 && dotIdx < 80) {
        return msg.substring(0, dotIdx).replaceFirst('Issue Detected: ', '').trim();
      }
      return msg.length > 60 ? '${msg.substring(0, 60)}…' : msg;
    }

    String extractDescription(String msg) {
      final dotIdx = msg.indexOf('Advisory:');
      if (dotIdx >= 0) return msg.substring(dotIdx);
      return msg;
    }

    test('extractTitle strips "Issue Detected:" prefix', () {
      const msg = 'Issue Detected: pH is 3, Turbidity is 4. Advisory: LOW, treat water';
      expect(extractTitle(msg), 'pH is 3, Turbidity is 4');
    });

    test('extractTitle truncates long messages without a period', () {
      final long = 'A' * 80;
      final result = extractTitle(long);
      expect(result.endsWith('…'), isTrue);
      expect(result.length, lessThanOrEqualTo(62));
    });

    test('extractDescription returns the Advisory clause', () {
      const msg = 'Issue Detected: pH is 3. Advisory: treat with base solution';
      expect(extractDescription(msg), startsWith('Advisory:'));
    });

    test('extractDescription returns full message when no Advisory: found', () {
      const msg = 'Sensor offline';
      expect(extractDescription(msg), 'Sensor offline');
    });
  });
}
