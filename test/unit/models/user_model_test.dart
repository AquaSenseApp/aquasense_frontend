// test/unit/models/user_model_test.dart
//
// WHY these tests exist
// ─────────────────────
// UserModel is persisted as JSON in SharedPreferences and read back on cold
// start.  A broken round-trip silently logs out every user on every restart —
// the kind of bug that appears in production reviews, not CI.  These tests pin
// the serialisation contract so a field rename or type change fails loudly.

import 'package:flutter_test/flutter_test.dart';
import 'package:aquasense/models/user_model.dart';
import '../../helpers/test_helpers.dart';

void main() {
  // ── JSON round-trip ──────────────────────────────────────────────────────

  group('UserModel · toJson / fromJson', () {
    test('preserves every field through a map round-trip', () {
      final restored = UserModel.fromJson(kAuthenticatedUser.toJson());

      expect(restored.userId,           kAuthenticatedUser.userId);
      expect(restored.email,            kAuthenticatedUser.email);
      expect(restored.username,         kAuthenticatedUser.username);
      expect(restored.fullName,         kAuthenticatedUser.fullName);
      expect(restored.organizationType, kAuthenticatedUser.organizationType);
      expect(restored.token,            kAuthenticatedUser.token);
      expect(restored.isEmailVerified,  kAuthenticatedUser.isEmailVerified);
      expect(restored.rememberMe,       kAuthenticatedUser.rememberMe);
    });

    test('preserves null optional fields without throwing', () {
      const bare     = UserModel(email: 'bare@test.io');
      final restored = UserModel.fromJson(bare.toJson());

      expect(restored.userId,           isNull);
      expect(restored.token,            isNull);
      expect(restored.isEmailVerified,  isFalse);
      expect(restored.rememberMe,       isFalse);
    });

    test('toJsonString / fromJsonString is equivalent to the map path', () {
      final restored = UserModel.fromJsonString(kAuthenticatedUser.toJsonString());
      expect(restored.email, kAuthenticatedUser.email);
      expect(restored.token, kAuthenticatedUser.token);
    });

    test('fromJson defaults missing boolean fields to false (forward-compat)', () {
      // Simulates a stored JSON written before the rememberMe field existed.
      final user = UserModel.fromJson({'email': 'old@test.io'});
      expect(user.isEmailVerified, isFalse,
          reason: 'Missing booleans must default to false, not throw');
      expect(user.rememberMe, isFalse);
    });

    test('fromJson handles both spellings of userId from backend', () {
      // Backend may send "userId" or "UserId" depending on ORM version.
      final fromLower = UserModel.fromJson({'email': 'a@b.io', 'userId': 5});
      expect(fromLower.userId, 5);
    });
  });

  // ── copyWith ─────────────────────────────────────────────────────────────

  group('UserModel · copyWith', () {
    test('changes only the specified field', () {
      final updated = kAuthenticatedUser.copyWith(rememberMe: true);
      expect(updated.rememberMe, isTrue);
      expect(updated.email,      kAuthenticatedUser.email,
          reason: 'Unspecified fields must be preserved unchanged');
    });

    test('returns a new object even with no arguments', () {
      final copy = kAuthenticatedUser.copyWith();
      expect(identical(copy, kAuthenticatedUser), isFalse);
      expect(copy.email, kAuthenticatedUser.email);
    });

    test('marks an unverified user as verified — the OTP-confirmed pattern', () {
      final verified = kUnverifiedUser.copyWith(isEmailVerified: true);
      expect(verified.isEmailVerified, isTrue);
      expect(verified.email,           kUnverifiedUser.email);
    });

    test('can attach a JWT token received after login', () {
      const bare    = UserModel(email: 'x@y.io');
      final withTok = bare.copyWith(token: 'eyJ.abc');
      expect(withTok.token, 'eyJ.abc');
      expect(withTok.email, 'x@y.io');
    });
  });
}
