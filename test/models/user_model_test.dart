import 'package:flutter_test/flutter_test.dart';
import 'package:aquasense/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('should create UserModel with required parameters', () {
      const user = UserModel(email: 'test@example.com');

      expect(user.email, 'test@example.com');
      expect(user.userId, null);
      expect(user.username, null);
      expect(user.fullName, null);
      expect(user.organizationType, null);
      expect(user.token, null);
      expect(user.isEmailVerified, false);
      expect(user.rememberMe, false);
    });

    test('should create UserModel with all parameters', () {
      const user = UserModel(
        userId: 1,
        email: 'test@example.com',
        username: 'testuser',
        fullName: 'Test User',
        organizationType: 'Engineering',
        token: 'jwt-token-123',
        isEmailVerified: true,
        rememberMe: true,
      );

      expect(user.userId, 1);
      expect(user.email, 'test@example.com');
      expect(user.username, 'testuser');
      expect(user.fullName, 'Test User');
      expect(user.organizationType, 'Engineering');
      expect(user.token, 'jwt-token-123');
      expect(user.isEmailVerified, true);
      expect(user.rememberMe, true);
    });

    test('copyWith should create a new instance with updated values', () {
      const original = UserModel(
        userId: 1,
        email: 'test@example.com',
        username: 'testuser',
      );

      final updated = original.copyWith(
        fullName: 'Updated Name',
        isEmailVerified: true,
      );

      expect(updated.userId, 1);
      expect(updated.email, 'test@example.com');
      expect(updated.username, 'testuser');
      expect(updated.fullName, 'Updated Name');
      expect(updated.isEmailVerified, true);
    });

    test('copyWith should preserve values when not specified', () {
      const original = UserModel(
        userId: 1,
        email: 'test@example.com',
        username: 'testuser',
        fullName: 'Test User',
        organizationType: 'Engineering',
        token: 'token-123',
        isEmailVerified: true,
        rememberMe: true,
      );

      final updated = original.copyWith(fullName: 'New Name');

      expect(updated.userId, original.userId);
      expect(updated.email, original.email);
      expect(updated.username, original.username);
      expect(updated.fullName, 'New Name');
      expect(updated.organizationType, original.organizationType);
      expect(updated.token, original.token);
      expect(updated.isEmailVerified, original.isEmailVerified);
      expect(updated.rememberMe, original.rememberMe);
    });

    group('JSON Serialization', () {
      test('toJson should return correct map', () {
        const user = UserModel(
          userId: 1,
          email: 'test@example.com',
          username: 'testuser',
          fullName: 'Test User',
          organizationType: 'Engineering',
          token: 'jwt-token',
          isEmailVerified: true,
          rememberMe: true,
        );

        final json = user.toJson();

        expect(json['userId'], 1);
        expect(json['email'], 'test@example.com');
        expect(json['username'], 'testuser');
        expect(json['fullName'], 'Test User');
        expect(json['organizationType'], 'Engineering');
        expect(json['token'], 'jwt-token');
        expect(json['isEmailVerified'], true);
        expect(json['rememberMe'], true);
      });

      test('fromJson should create UserModel from map', () {
        final json = {
          'userId': 1,
          'email': 'test@example.com',
          'username': 'testuser',
          'fullName': 'Test User',
          'organizationType': 'Engineering',
          'token': 'jwt-token',
          'isEmailVerified': true,
          'rememberMe': true,
        };

        final user = UserModel.fromJson(json);

        expect(user.userId, 1);
        expect(user.email, 'test@example.com');
        expect(user.username, 'testuser');
        expect(user.fullName, 'Test User');
        expect(user.organizationType, 'Engineering');
        expect(user.token, 'jwt-token');
        expect(user.isEmailVerified, true);
        expect(user.rememberMe, true);
      });

      test('fromJson should handle missing optional fields', () {
        final json = {
          'email': 'test@example.com',
        };

        final user = UserModel.fromJson(json);

        expect(user.email, 'test@example.com');
        expect(user.userId, null);
        expect(user.username, null);
        expect(user.fullName, null);
        expect(user.organizationType, null);
        expect(user.token, null);
        expect(user.isEmailVerified, false);
        expect(user.rememberMe, false);
      });

      test('fromJson should handle null values for optional fields', () {
        final json = {
          'userId': null,
          'email': 'test@example.com',
          'username': null,
          'fullName': null,
          'organizationType': null,
          'token': null,
          'isEmailVerified': null,
          'rememberMe': null,
        };

        final user = UserModel.fromJson(json);

        expect(user.userId, null);
        expect(user.email, 'test@example.com');
        expect(user.username, null);
        expect(user.fullName, null);
        expect(user.organizationType, null);
        expect(user.token, null);
        expect(user.isEmailVerified, false);
        expect(user.rememberMe, false);
      });

      test('toJsonString should return JSON string', () {
        const user = UserModel(
          email: 'test@example.com',
          username: 'testuser',
        );

        final jsonString = user.toJsonString();

        expect(jsonString.contains('test@example.com'), true);
        expect(jsonString.contains('testuser'), true);
      });

      test('fromJsonString should create UserModel from JSON string', () {
        const user = UserModel(
          userId: 1,
          email: 'test@example.com',
          username: 'testuser',
        );

        final jsonString = user.toJsonString();
        final restored = UserModel.fromJsonString(jsonString);

        expect(restored.userId, user.userId);
        expect(restored.email, user.email);
        expect(restored.username, user.username);
      });

      test('round-trip serialization should preserve all data', () {
        const original = UserModel(
          userId: 42,
          email: 'roundtrip@test.com',
          username: 'roundtrip_user',
          fullName: 'Round Trip User',
          organizationType: 'Testing',
          token: 'secure-token-abc123',
          isEmailVerified: true,
          rememberMe: true,
        );

        final jsonString = original.toJsonString();
        final restored = UserModel.fromJsonString(jsonString);

        expect(restored.userId, original.userId);
        expect(restored.email, original.email);
        expect(restored.username, original.username);
        expect(restored.fullName, original.fullName);
        expect(restored.organizationType, original.organizationType);
        expect(restored.token, original.token);
        expect(restored.isEmailVerified, original.isEmailVerified);
        expect(restored.rememberMe, original.rememberMe);
      });
    });
  });
}
