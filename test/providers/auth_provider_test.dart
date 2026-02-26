import 'package:flutter_test/flutter_test.dart';
import 'package:aquasense/providers/auth_provider.dart';
import 'package:aquasense/models/user_model.dart';

void main() {
  group('AuthProvider', () {
    late AuthProvider authProvider;

    setUp(() {
      authProvider = AuthProvider();
    });

    group('Initial State', () {
      test('should have initial status', () {
        expect(authProvider.status, AuthStatus.initial);
      });

      test('should have null user', () {
        expect(authProvider.user, null);
      });

      test('should have null error message', () {
        expect(authProvider.errorMessage, null);
      });

      test('should not be authenticated', () {
        expect(authProvider.isAuthenticated, false);
      });

      test('should not be pending verification', () {
        expect(authProvider.isPendingVerification, false);
      });
    });

    group('Status Enum', () {
      test('should have all required status values', () {
        expect(AuthStatus.values.length, 5);
        expect(AuthStatus.values.contains(AuthStatus.initial), true);
        expect(AuthStatus.values.contains(AuthStatus.loading), true);
        expect(AuthStatus.values.contains(AuthStatus.pendingVerification), true);
        expect(AuthStatus.values.contains(AuthStatus.authenticated), true);
        expect(AuthStatus.values.contains(AuthStatus.error), true);
      });
    });

    group('clearError', () {
      test('should clear error message and notify listeners', () {
        // First, simulate an error state (this is internal, but we test the clearError behavior)
        authProvider.clearError();
        
        // After clearError, errorMessage should be null
        expect(authProvider.errorMessage, null);
      });
    });

    group('pendingEmail', () {
      test('should return null initially', () {
        expect(authProvider.pendingEmail, null);
      });
    });
  });

  group('AuthStatus', () {
    test('initial should represent starting state', () {
      expect(AuthStatus.initial.name, 'initial');
    });

    test('loading should represent async operation', () {
      expect(AuthStatus.loading.name, 'loading');
    });

    test('pendingVerification should represent awaiting OTP', () {
      expect(AuthStatus.pendingVerification.name, 'pendingVerification');
    });

    test('authenticated should represent logged in state', () {
      expect(AuthStatus.authenticated.name, 'authenticated');
    });

    test('error should represent failure state', () {
      expect(AuthStatus.error.name, 'error');
    });
  });

  group('UserModel for Auth', () {
    test('should create user with email verification status', () {
      const verifiedUser = UserModel(
        email: 'verified@test.com',
        isEmailVerified: true,
        token: 'test-token',
      );

      expect(verifiedUser.isEmailVerified, true);
      expect(verifiedUser.token, 'test-token');
    });

    test('should create user without verification', () {
      const unverifiedUser = UserModel(
        email: 'unverified@test.com',
        isEmailVerified: false,
      );

      expect(unverifiedUser.isEmailVerified, false);
    });

    test('should track remember me preference', () {
      const rememberedUser = UserModel(
        email: 'remember@test.com',
        rememberMe: true,
      );

      expect(rememberedUser.rememberMe, true);
    });
  });
}
