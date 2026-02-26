// test/unit/providers/reading_provider_test.dart
//
// WHY these tests exist
// ─────────────────────
// ReadingProvider is scoped to ReadingUploadScreen — a new instance starts
// every time the screen opens and is disposed when the user navigates away.
// Its state machine has three mutually exclusive outcomes:
//
//   (a) isLoading=true  → spinner shown, form disabled
//   (b) result != null  → analysis card shown
//   (c) errorMessage != null → red banner shown
//
// If two of these are true at the same time the screen renders both a success
// card and an error banner simultaneously.  The tests below pin the mutual
// exclusivity of those states.

import 'package:flutter_test/flutter_test.dart';
import 'package:aquasense/providers/reading_provider.dart';
import 'package:aquasense/services/reading_service.dart';
import '../../helpers/test_helpers.dart';

void main() {
  late ReadingProvider provider;

  setUp(() {
    setupFakeSharedPrefs();
    provider = ReadingProvider();
  });

  // ── Initial state ─────────────────────────────────────────────────────────

  group('ReadingProvider · initial state', () {
    test('isLoading starts false', () {
      expect(provider.isLoading, isFalse);
    });

    test('result starts null', () {
      expect(provider.result, isNull);
    });

    test('errorMessage starts null', () {
      expect(provider.errorMessage, isNull);
    });
  });

  // ── Seeded success state ──────────────────────────────────────────────────
  // We seed the result directly via the @visibleForTesting method to verify
  // that the success path clears the error and loading states.

  group('ReadingProvider · success state (seeded)', () {
    final successResponse = ReadingUploadResponse(
      message: 'Data analyzed and recorded',
      readings: [
        const AnalysedReading(
          parameter: 'PH',
          value:     3.0,
          result:    'LOW, The water is acidic, treat with alkaline solution',
        ),
        const AnalysedReading(
          parameter: 'Turbidity',
          value:     4.0,
          result:    'LOW / OPTIMUM, The water is safe and good for use',
        ),
      ],
    );

    setUp(() {
      provider.setResultForTest(successResponse);
    });

    test('result is set to the backend response', () {
      expect(provider.result, isNotNull);
      expect(provider.result!.message, 'Data analyzed and recorded');
    });

    test('result contains all analysed readings', () {
      expect(provider.result!.readings.length, 2);
    });

    test('isLoading is false after success — spinner must not stay visible', () {
      expect(provider.isLoading, isFalse);
    });

    test('errorMessage is null on success — error banner must not show', () {
      expect(provider.errorMessage, isNull);
    });

    test('success state notifies listeners', () {
      var notified = false;
      // Fresh provider to capture exactly one notification
      final p = ReadingProvider();
      p.addListener(() => notified = true);
      p.setResultForTest(successResponse);
      expect(notified, isTrue);
    });
  });

  // ── Seeded error state ────────────────────────────────────────────────────

  group('ReadingProvider · error state (seeded)', () {
    setUp(() {
      provider.setResultForTest(null, errorMessage: 'No internet connection. Check your network.');
    });

    test('errorMessage is set', () {
      expect(provider.errorMessage, isNotNull);
      expect(provider.errorMessage, contains('internet'));
    });

    test('result is null on error — success card must not show', () {
      expect(provider.result, isNull);
    });

    test('isLoading is false on error', () {
      expect(provider.isLoading, isFalse);
    });
  });

  // ── reset() ───────────────────────────────────────────────────────────────

  group('ReadingProvider · reset()', () {
    test('clears result after a successful upload', () {
      provider.setResultForTest(ReadingUploadResponse(message: 'ok', readings: []));
      provider.reset();
      expect(provider.result, isNull);
    });

    test('clears errorMessage after a failed upload', () {
      provider.setResultForTest(null, errorMessage: 'Network error');
      provider.reset();
      expect(provider.errorMessage, isNull);
    });

    test('notifies listeners on reset', () {
      var notified = false;
      provider.addListener(() => notified = true);
      provider.reset();
      expect(notified, isTrue);
    });

    test('is a no-op on a fresh provider — does not throw', () {
      expect(() => provider.reset(), returnsNormally);
    });
  });

  // ── State mutual exclusivity ──────────────────────────────────────────────

  group('ReadingProvider · mutual exclusivity invariant', () {
    test('result and errorMessage are never both set simultaneously', () {
      // After a successful upload, errorMessage must be null
      provider.setResultForTest(
        ReadingUploadResponse(message: 'ok', readings: []),
      );
      expect(provider.result,       isNotNull);
      expect(provider.errorMessage, isNull);

      // After an error, result must be null
      provider.setResultForTest(null, errorMessage: 'oops');
      expect(provider.result,       isNull);
      expect(provider.errorMessage, isNotNull);
    });
  });
}
