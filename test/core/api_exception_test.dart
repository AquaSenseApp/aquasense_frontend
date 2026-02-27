import 'package:flutter_test/flutter_test.dart';
import 'package:aquasense/core/errors/api_exception.dart';

void main() {
  group('ApiException', () {
    test('should create ApiException with required message', () {
      const exception = ApiException(message: 'Test error message');

      expect(exception.message, 'Test error message');
      expect(exception.statusCode, isNull);
    });

    test('should create ApiException with status code', () {
      const exception = ApiException(
        statusCode: 404,
        message: 'Not Found',
      );

      expect(exception.statusCode, 404);
      expect(exception.message, 'Not Found');
    });

    test('toString returns formatted string', () {
      const exception = ApiException(
        statusCode: 404,
        message: 'Not Found',
      );

      expect(exception.toString(), 'ApiException(404): Not Found');
    });

    test('toString handles null statusCode', () {
      const exception = ApiException(
        message: 'Network error',
      );

      expect(exception.toString(), 'ApiException(null): Network error');
    });

    group('isNetworkError', () {
      test('returns true when statusCode is null', () {
        const exception = ApiException(message: 'Network error');

        expect(exception.isNetworkError, true);
      });

      test('returns false when statusCode is provided', () {
        const exception = ApiException(
          statusCode: 404,
          message: 'Not Found',
        );

        expect(exception.isNetworkError, false);
      });
    });

    group('isUnauthorised', () {
      test('returns true when statusCode is 401', () {
        const exception = ApiException(
          statusCode: 401,
          message: 'Unauthorized',
        );

        expect(exception.isUnauthorised, true);
      });

      test('returns false when statusCode is not 401', () {
        const exception = ApiException(
          statusCode: 404,
          message: 'Not Found',
        );

        expect(exception.isUnauthorised, false);
      });

      test('returns false when statusCode is null', () {
        const exception = ApiException(message: 'Network error');

        expect(exception.isUnauthorised, false);
      });
    });

    group('displayMessage', () {
      test('returns network error message when statusCode is null', () {
        const exception = ApiException(message: 'Network error');

        expect(exception.displayMessage, 'No internet connection. Check your network.');
      });

      test('returns session expired message when statusCode is 401', () {
        const exception = ApiException(
          statusCode: 401,
          message: 'Unauthorized',
        );

        expect(exception.displayMessage, 'Session expired. Please sign in again.');
      });

      test('returns original message for other status codes', () {
        const exception = ApiException(
          statusCode: 500,
          message: 'Internal Server Error',
        );

        expect(exception.displayMessage, 'Internal Server Error');
      });

      test('returns original message for non-401 client errors', () {
        const exception = ApiException(
          statusCode: 400,
          message: 'Bad Request',
        );

        expect(exception.displayMessage, 'Bad Request');
      });
    });
  });
}
