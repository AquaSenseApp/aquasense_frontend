// test/unit/services/alert_dto_test.dart
//
// WHY these tests exist
// ─────────────────────
// ApiAlertDto.fromJson parses the raw backend payload.  The backend uses
// capitalised key "ReadingId" (Sequelize ORM convention) rather than the
// camelCase "readingId" you might expect.  A wrong key mapping means every
// alert arrives with readingId=0 — silently incorrect data, not an exception.
//
// ApiAlertDto.toModel converts the raw DTO into the AlertModel the UI renders.
// The title extraction strips "Issue Detected: " from the backend message.
// If that stripping breaks, every alert card shows "Issue Detected: pH is 3…"
// as its title instead of just "pH is 3, Turbidity is 4".

import 'package:flutter_test/flutter_test.dart';
import 'package:aquasense/services/alert_service.dart';
import 'package:aquasense/models/alert_model.dart';
import '../../helpers/test_helpers.dart';

// Canonical backend alert payload — matches the sample JSON in the spec.
const _rawAlertJson = {
  'id':        2,
  'message':   'Issue Detected: pH is 3, Turbidity is 4. Advisory: LOW, '
               'The water is acidic, treat with alkaline solution to neutralise it',
  'status':    'active',
  'createdAt': '2026-02-24T14:21:30.000Z',
  'updatedAt': '2026-02-24T14:21:30.000Z',
  'ReadingId': 3,
  'Reading':   null,
};

void main() {
  // ── ApiAlertDto.fromJson ───────────────────────────────────────────────────

  group('ApiAlertDto · fromJson', () {
    late ApiAlertDto dto;

    setUp(() => dto = ApiAlertDto.fromJson(_rawAlertJson));

    test('parses id', () {
      expect(dto.id, 2);
    });

    test('parses message verbatim', () {
      expect(dto.message, startsWith('Issue Detected:'));
    });

    test('parses status as "active"', () {
      expect(dto.status, 'active');
      expect(dto.isResolved, isFalse);
    });

    test('parses createdAt as a DateTime', () {
      expect(dto.createdAt, isA<DateTime>());
      expect(dto.createdAt.year,  2026);
      expect(dto.createdAt.month, 2);
      expect(dto.createdAt.day,   24);
    });

    test('reads ReadingId from capital-R key (Sequelize ORM convention)', () {
      expect(dto.readingId, 3,
          reason: 'The backend uses "ReadingId" not "readingId" — lowercase '
              'would parse as 0 and break reading correlation');
    });

    test('falls back to readingId=0 when ReadingId is absent', () {
      final dto2 = ApiAlertDto.fromJson({
        'id':        1,
        'message':   'test',
        'status':    'active',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-01T00:00:00.000Z',
        // No ReadingId key
      });
      expect(dto2.readingId, 0);
    });

    test('defaults status to "active" when key is missing', () {
      final dto2 = ApiAlertDto.fromJson({
        'id':        1,
        'message':   'test',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-01T00:00:00.000Z',
        'ReadingId': 0,
      });
      expect(dto2.status, 'active');
    });
  });

  // ── isResolved ────────────────────────────────────────────────────────────

  group('ApiAlertDto · isResolved', () {
    test('is true when status is "resolved"', () {
      final resolved = ApiAlertDto.fromJson({
        ..._rawAlertJson,
        'status': 'resolved',
      });
      expect(resolved.isResolved, isTrue);
    });

    test('is false when status is "active"', () {
      final active = ApiAlertDto.fromJson(_rawAlertJson);
      expect(active.isResolved, isFalse);
    });
  });

  // ── toModel — title extraction ────────────────────────────────────────────

  group('ApiAlertDto · toModel() title extraction', () {
    test('strips "Issue Detected: " prefix from title', () {
      final model = ApiAlertDto.fromJson(_rawAlertJson).toModel();
      expect(model.title, isNot(startsWith('Issue Detected:')),
          reason: 'The prefix is visual clutter on the card — the card header '
              'already communicates that this is an issue');
    });

    test('title contains the parameter readings', () {
      final model = ApiAlertDto.fromJson(_rawAlertJson).toModel();
      // "pH is 3, Turbidity is 4" should survive stripping
      expect(model.title, contains('pH'));
    });

    test('description starts with "Advisory:" clause', () {
      final model = ApiAlertDto.fromJson(_rawAlertJson).toModel();
      expect(model.description, startsWith('Advisory:'));
    });

    test('apiId on the model matches the DTO id', () {
      final model = ApiAlertDto.fromJson(_rawAlertJson).toModel();
      expect(model.apiId, 2);
    });

    test('status is preserved on the model', () {
      final model = ApiAlertDto.fromJson(_rawAlertJson).toModel();
      expect(model.isActive, isTrue);
    });

    test('timestamp on model matches createdAt', () {
      final model = ApiAlertDto.fromJson(_rawAlertJson).toModel();
      expect(model.timestamp.year,  2026);
      expect(model.timestamp.month, 2);
      expect(model.timestamp.day,   24);
    });
  });

  // ── toModel — type inference ──────────────────────────────────────────────

  group('ApiAlertDto · toModel() type inference', () {
    AlertModel alertWithMessage(String msg) {
      return ApiAlertDto.fromJson({
        ..._rawAlertJson,
        'message': msg,
      }).toModel();
    }

    test('message containing "Advisory" → AlertType.recommendation', () {
      final model = alertWithMessage('Advisory: Do X.');
      expect(model.type, AlertType.recommendation);
    });

    test('message containing "anomal" → AlertType.anomaly', () {
      final model = alertWithMessage('Anomaly detected in sensor.');
      expect(model.type, AlertType.anomaly);
    });

    test('message containing "compli" → AlertType.compliance', () {
      final model = alertWithMessage('Non-compliance detected.');
      expect(model.type, AlertType.compliance);
    });

    test('generic message defaults to AlertType.alert', () {
      final model = alertWithMessage('pH is dangerously high.');
      expect(model.type, AlertType.alert);
    });
  });
}
