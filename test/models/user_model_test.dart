import 'package:flutter_test/flutter_test.dart';
import 'package:aquasense/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('should create UserModel with required fields', () {
      const user = UserModel(email: 'test@example.com');

      expect(user.email, 'test@example.com');
      expect(user.userId, isNull);
      expect(user.username, isNull);
      expect(user.fullName, isNull);
      expect(user.token, isNull);
      expect(user.isEmailVerified, false);
      expect(user.rememberMe, false);
    });

    test('should create UserModel with all fields', () {
      const user = UserModel(
        userId: 123,
        email: 'test@example.com',
        username: 'testuser',
        fullName: 'Test User',
        organizationType: 'Industrial',
        token: 'jwt-token-123',
        isEmailVerified: true,
        rememberMe: true,
      );

      expect(user.userId, 123);
      expect(user.email, 'test@example.com');
      expect(user.username, 'testuser');
      expect(user.fullName, 'Test User');
      expect(user.organizationType, 'Industrial');
      expect(user.token, 'jwt-token-123');
      expect(user.isEmailVerified, true);
      expect(user.rememberMe, true);
    });

    test('copyWith should create a new instance with updated fields', () {
      const original = UserModel(
        userId: 123,
        email: 'test@example.com',
        username: 'testuser',
      );

      final updated = original.copyWith(
        email: 'newemail@example.com',
        token: 'new-token',
      );

      // Original should be unchanged
      expect(original.email, 'test@example.com');
      expect(original.token, isNull);

      // Updated should have new values
      expect(updated.email, 'newemail@example.com');
      expect(updated.token, 'new-token');
      expect(updated.userId, 123); // unchanged
      expect(updated.username, 'testuser'); // unchanged
    });

    test('toJson should serialize all fields correctly', () {
      const user = UserModel(
        userId: 123,
        email: 'test@example.com',
        username: 'testuser',
        fullName: 'Test User',
        organizationType: 'Industrial',
        token: 'jwt-token',
        isEmailVerified: true,
        rememberMe: true,
      );

      final json = user.toJson();

      expect(json['userId'], 123);
      expect(json['email'], 'test@example.com');
      expect(json['username'], 'testuser');
      expect(json['fullName'], 'Test User');
      expect(json['organizationType'], 'Industrial');
      expect(json['token'], 'jwt-token');
      expect(json['isEmailVerified'], true);
      expect(json['rememberMe'], true);
    });

    test('fromJson should deserialize all fields correctly', () {
      final json = {
        'userId': 123,
        'email': 'test@example.com',
        'username': 'testuser',
        'fullName': 'Test User',
        'organizationType': 'Industrial',
        'token': 'jwt-token',
        'isEmailVerified': true,
        'rememberMe': true,
      };

      final user = UserModel.fromJson(json);

      expect(user.userId, 123);
      expect(user.email, 'test@example.com');
      expect(user.username, 'testuser');
      expect(user.fullName, 'Test User');
      expect(user.organizationType, 'Industrial');
      expect(user.token, 'jwt-token');
      expect(user.isEmailVerified, true);
      expect(user.rememberMe, true);
    });

    test('fromJson should handle missing optional fields with defaults', () {
      final json = {
        'email': 'test@example.com',
      };

      final user = UserModel.fromJson(json);

      expect(user.email, 'test@example.com');
      expect(user.userId, isNull);
      expect(user.username, isNull);
      expect(user.isEmailVerified, false);
      expect(user.rememberMe, false);
    });

    test('toJsonString and fromJsonString should be reversible', () {
      const original = UserModel(
        userId: 123,
        email: 'test@example.com',
        username: 'testuser',
        fullName: 'Test User',
        token: 'jwt-token',
      );

      final jsonString = original.toJsonString();
      final restored = UserModel.fromJsonString(jsonString);

      expect(restored.email, original.email);
      expect(restored.userId, original.userId);
      expect(restored.username, original.username);
      expect(restored.fullName, original.fullName);
      expect(restored.token, original.token);
    });
  });
}
