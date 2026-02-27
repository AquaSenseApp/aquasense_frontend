import 'package:flutter_test/flutter_test.dart';
import 'package:aquasense/services/alert_service.dart';
import 'package:aquasense/models/alert_model.dart';

void main() {
  group('ApiAlertDto', () {
    test('fromJson creates instance with required fields', () {
      final json = {
        'id': 1,
        'message': 'Test alert message',
        'status': 'active',
        'createdAt': '2024-01-01T10:00:00Z',
        'updatedAt': '2024-01-01T10:00:00Z',
        'ReadingId': 123,
      };

      final dto = ApiAlertDto.fromJson(json);

      expect(dto.id, 1);
      expect(dto.message, 'Test alert message');
      expect(dto.status, 'active');
      expect(dto.createdAt, DateTime.parse('2024-01-01T10:00:00Z'));
      expect(dto.updatedAt, DateTime.parse('2024-01-01T10:00:00Z'));
      expect(dto.readingId, 123);
    });

    test('fromJson handles missing optional status', () {
      final json = {
        'id': 1,
        'message': 'Test alert message',
        'createdAt': '2024-01-01T10:00:00Z',
        'updatedAt': '2024-01-01T10:00:00Z',
      };

      final dto = ApiAlertDto.fromJson(json);

      expect(dto.status, 'active');
    });

    test('fromJson handles missing ReadingId', () {
      final json = {
        'id': 1,
        'message': 'Test alert message',
        'status': 'active',
        'createdAt': '2024-01-01T10:00:00Z',
        'updatedAt': '2024-01-01T10:00:00Z',
      };

      final dto = ApiAlertDto.fromJson(json);

      expect(dto.readingId, 0);
    });

    group('isResolved', () {
      test('returns true when status is resolved', () {
        final dto = ApiAlertDto.fromJson({
          'id': 1,
          'message': 'Test',
          'status': 'resolved',
          'createdAt': '2024-01-01T10:00:00Z',
          'updatedAt': '2024-01-01T10:00:00Z',
        });

        expect(dto.isResolved, true);
      });

      test('returns false when status is active', () {
        final dto = ApiAlertDto.fromJson({
          'id': 1,
          'message': 'Test',
          'status': 'active',
          'createdAt': '2024-01-01T10:00:00Z',
          'updatedAt': '2024-01-01T10:00:00Z',
        });

        expect(dto.isResolved, false);
      });
    });

    group('toModel', () {
      test('converts to AlertModel correctly', () {
        final dto = ApiAlertDto.fromJson({
          'id': 1,
          'message': 'Issue Detected: pH is 3. Advisory: Check the system.',
          'status': 'active',
          'createdAt': '2024-01-01T10:00:00Z',
          'updatedAt': '2024-01-01T10:00:00Z',
          'ReadingId': 123,
        });

        final model = dto.toModel();

        expect(model.id, '1');
        expect(model.apiId, 1);
        expect(model.type, AlertType.alert);
        expect(model.status, 'active');
        expect(model.timestamp, dto.createdAt);
      });

      test('infers recommendation type from message', () {
        final dto = ApiAlertDto.fromJson({
          'id': 2,
          'message': 'We recommend checking the pH levels.',
          'status': 'active',
          'createdAt': '2024-01-01T10:00:00Z',
          'updatedAt': '2024-01-01T10:00:00Z',
        });

        final model = dto.toModel();

        expect(model.type, AlertType.recommendation);
      });

      test('infers advisory type from message', () {
        final dto = ApiAlertDto.fromJson({
          'id': 3,
          'message': 'Advisory: Temperature is rising.',
          'status': 'active',
          'createdAt': '2024-01-01T10:00:00Z',
          'updatedAt': '2024-01-01T10:00:00Z',
        });

        final model = dto.toModel();

        expect(model.type, AlertType.recommendation);
      });

      test('infers anomaly type from message', () {
        final dto = ApiAlertDto.fromJson({
          'id': 4,
          'message': 'Anomaly detected in readings.',
          'status': 'active',
          'createdAt': '2024-01-01T10:00:00Z',
          'updatedAt': '2024-01-01T10:00:00Z',
        });

        final model = dto.toModel();

        expect(model.type, AlertType.anomaly);
      });

      test('infers compliance type from message', () {
        final dto = ApiAlertDto.fromJson({
          'id': 5,
          'message': 'Compliance check failed.',
          'status': 'active',
          'createdAt': '2024-01-01T10:00:00Z',
          'updatedAt': '2024-01-01T10:00:00Z',
        });

        final model = dto.toModel();

        expect(model.type, AlertType.compliance);
      });

      test('extracts title from message with dot', () {
        final dto = ApiAlertDto.fromJson({
          'id': 6,
          'message': 'Issue Detected: pH is 3, Turbidity is 4. Advisory: Check.',
          'status': 'active',
          'createdAt': '2024-01-01T10:00:00Z',
          'updatedAt': '2024-01-01T10:00:00Z',
        });

        final model = dto.toModel();

        expect(model.title, 'pH is 3, Turbidity is 4');
      });

      test('handles long messages with truncation', () {
        final longMessage = 'A' * 100;
        final dto = ApiAlertDto.fromJson({
          'id': 7,
          'message': longMessage,
          'status': 'active',
          'createdAt': '2024-01-01T10:00:00Z',
          'updatedAt': '2024-01-01T10:00:00Z',
        });

        final model = dto.toModel();

        expect(model.title.length, lessThanOrEqualTo(63)); // 60 + '…'
      });

      test('extracts description from Advisory section', () {
        final dto = ApiAlertDto.fromJson({
          'id': 8,
          'message': 'Issue Detected: pH is low. Advisory: Add alkaline buffer.',
          'status': 'active',
          'createdAt': '2024-01-01T10:00:00Z',
          'updatedAt': '2024-01-01T10:00:00Z',
        });

        final model = dto.toModel();

        expect(model.description, 'Advisory: Add alkaline buffer.');
      });
    });
  });
}
