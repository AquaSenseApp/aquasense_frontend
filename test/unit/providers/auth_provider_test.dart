// test/unit/providers/auth_provider_test.dart
//
// WHY these tests exist
// ─────────────────────
// AuthProvider is the state machine every screen reacts to.  It drives
// navigation (splash → home vs splash → onboarding), OTP gating, and
// SharedPreferences persistence.  A wrong status transition — e.g. setting
// authenticated=true while leaving user=null — would crash every screen
// that reads auth.user!.userId.
//
// Testing strategy
// ────────────────
// We avoid making real HTTP calls by only testing the methods that do NOT
// call the backend (restoreSession, verifyOtp, signOut, clearError, and the
// validation guards inside signIn/createAccount).  The methods that need the
// network (signIn success, createAccount success) are covered at the
// integration layer where a real or mock server is available.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aquasense/providers/auth_provider.dart';
import 'package:aquasense/models/user_model.dart';
import '../../helpers/test_helpers.dart';

void main() {
  late AuthProvider auth;

  setUp(() {
    setupFakeSharedPrefs();
    auth = AuthProvider();
  });

  // ── Initial state ─────────────────────────────────────────────────────────

  group('AuthProvider · initial state', () {
    test('starts as AuthStatus.initial', () {
      expect(auth.status, AuthStatus.initial);
    });

    test('user is null before any operation', () {
      expect(auth.user, isNull);
    });

    test('isAuthenticated is false', () {
      expect(auth.isAuthenticated, isFalse);
    });

    test('isPendingVerification is false', () {
      expect(auth.isPendingVerification, isFalse);
    });

    test('errorMessage is null', () {
      expect(auth.errorMessage, isNull);
    });
  });

  // ── restoreSession ────────────────────────────────────────────────────────

  group('AuthProvider · restoreSession()', () {
    test('returns false and stays initial when prefs are empty', () async {
      expect(await auth.restoreSession(), isFalse);
      expect(auth.status, AuthStatus.initial);
    });

    test('returns true and sets authenticated for a valid verified session', () async {
      SharedPreferences.setMockInitialValues({
        'aquasense_user':           kAuthenticatedUser.toJsonString(),
        'aquasense_email_verified': true,
      });
      auth = AuthProvider(); // fresh instance reads new prefs

      expect(await auth.restoreSession(), isTrue);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.user?.email, kAuthenticatedUser.email);
    });

    test('returns false when stored user is not email-verified', () async {
      // An unverified draft was stored during registration before OTP
      SharedPreferences.setMockInitialValues({
        'aquasense_user': kUnverifiedUser.toJsonString(),
      });
      auth = AuthProvider();

      expect(await auth.restoreSession(), isFalse,
          reason: 'Unverified users must go through OTP even after restart');
    });

    test('returns false and clears corrupted prefs without crashing', () async {
      SharedPreferences.setMockInitialValues({
        'aquasense_user': 'not-valid-json{{{',
      });
      auth = AuthProvider();

      expect(await auth.restoreSession(), isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('aquasense_user'), isNull,
          reason: 'Corrupted prefs must be cleared to prevent a crash loop');
    });

    test('notifies listeners when restoring a valid session', () async {
      SharedPreferences.setMockInitialValues({
        'aquasense_user':           kAuthenticatedUser.toJsonString(),
        'aquasense_email_verified': true,
      });
      auth = AuthProvider();

      var notified = false;
      auth.addListener(() => notified = true);

      await auth.restoreSession();
      expect(notified, isTrue);
    });
  });

  // ── OTP verification ──────────────────────────────────────────────────────
  // We use the @visibleForTesting seeder to skip the network call and put
  // the provider directly into pendingVerification with a known OTP.

  group('AuthProvider · verifyOtp()', () {
    test('wrong code → returns false, sets error status', () async {
      auth.setPendingStateForTest(
        email: 'u@test.io', otp: '12345', user: kUnverifiedUser,
      );

      expect(await auth.verifyOtp('00000'), isFalse);
      expect(auth.status, AuthStatus.error);
      expect(auth.errorMessage, isNotNull);
    });

    test('correct code → returns true, transitions to authenticated', () async {
      auth.setPendingStateForTest(
        email: 'u@test.io', otp: '12345', user: kUnverifiedUser,
      );

      expect(await auth.verifyOtp('12345'), isTrue);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.status, AuthStatus.authenticated);
    });

    test('correct code → writes isEmailVerified=true to SharedPreferences', () async {
      auth.setPendingStateForTest(
        email: 'u@test.io', otp: '99999', user: kUnverifiedUser,
      );

      await auth.verifyOtp('99999');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('aquasense_email_verified'), isTrue,
          reason: 'The verified flag must persist so restoreSession skips OTP next launch');
    });

    test('correct code → clears pendingEmail', () async {
      auth.setPendingStateForTest(
        email: 'u@test.io', otp: '11111', user: kUnverifiedUser,
      );

      await auth.verifyOtp('11111');
      expect(auth.pendingEmail, isNull);
    });

    test('verifyOtp on unprimed provider returns false (no OTP set)', () async {
      // Provider is in initial state — no _pendingOtp
      expect(await auth.verifyOtp('00000'), isFalse);
    });
  });

  // ── resendOtp ─────────────────────────────────────────────────────────────

  group('AuthProvider · resendOtp()', () {
    test('invalidates the previous OTP — old code no longer works', () async {
      auth.setPendingStateForTest(
        email: 'u@test.io', otp: '11111', user: kUnverifiedUser,
      );

      await auth.resendOtp();

      // The old OTP should now fail
      expect(await auth.verifyOtp('11111'), isFalse,
          reason: 'After resend, the old code must be rejected');
    });

    test('notifies listeners after generating a new OTP', () async {
      auth.setPendingStateForTest(
        email: 'u@test.io', otp: '11111', user: kUnverifiedUser,
      );

      var notified = false;
      auth.addListener(() => notified = true);

      await auth.resendOtp();
      expect(notified, isTrue);
    });
  });

  // ── signIn validation (no network) ───────────────────────────────────────

  group('AuthProvider · signIn() — local validation', () {
    test('empty email → returns false, sets error', () async {
      expect(await auth.signIn(email: '', password: 'pass123'), isFalse);
      expect(auth.status, AuthStatus.error);
    });

    test('empty password → returns false, sets error', () async {
      expect(await auth.signIn(email: 'a@b.io', password: ''), isFalse);
      expect(auth.status, AuthStatus.error);
    });

    test('error message is non-empty after validation failure', () async {
      await auth.signIn(email: '', password: '');
      expect(auth.errorMessage, isNotEmpty);
    });
  });

  // ── createAccount validation (no network) ────────────────────────────────

  group('AuthProvider · createAccount() — local validation', () {
    test('empty username → returns false', () async {
      expect(await auth.createAccount(
        username: '', fullName: 'T', email: 't@t.io',
        password: 'pass', organizationType: 'School',
      ), isFalse);
    });

    test('empty email → returns false', () async {
      expect(await auth.createAccount(
        username: 'u', fullName: 'T', email: '',
        password: 'pass', organizationType: 'School',
      ), isFalse);
    });

    test('empty password → returns false', () async {
      expect(await auth.createAccount(
        username: 'u', fullName: 'T', email: 't@t.io',
        password: '', organizationType: 'School',
      ), isFalse);
    });
  });

  // ── signOut ───────────────────────────────────────────────────────────────

  group('AuthProvider · signOut()', () {
    test('clears user, resets status, removes all prefs keys', () async {
      // Seed a full authenticated session in prefs
      SharedPreferences.setMockInitialValues({
        'aquasense_user':           kAuthenticatedUser.toJsonString(),
        'aquasense_token':          'eyJ.test',
        'aquasense_email_verified': true,
        'aquasense_remember_me':    true,
      });
      auth = AuthProvider();
      await auth.restoreSession();
      expect(auth.isAuthenticated, isTrue);

      await auth.signOut();

      expect(auth.user,            isNull);
      expect(auth.isAuthenticated, isFalse);
      expect(auth.status,          AuthStatus.initial);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('aquasense_user'),  isNull);
      expect(prefs.getString('aquasense_token'), isNull);
      expect(prefs.getBool('aquasense_email_verified'), isNull);
      expect(prefs.getBool('aquasense_remember_me'),    isNull);
    });

    test('notifies listeners after sign out', () async {
      SharedPreferences.setMockInitialValues({
        'aquasense_user':           kAuthenticatedUser.toJsonString(),
        'aquasense_email_verified': true,
      });
      auth = AuthProvider();
      await auth.restoreSession();

      var notified = false;
      auth.addListener(() => notified = true);

      await auth.signOut();
      expect(notified, isTrue);
    });
  });

  // ── clearError ────────────────────────────────────────────────────────────

  group('AuthProvider · clearError()', () {
    test('clears errorMessage after a validation failure', () async {
      await auth.signIn(email: '', password: '');
      expect(auth.errorMessage, isNotNull);

      auth.clearError();
      expect(auth.errorMessage, isNull);
    });

    test('does not throw when called with no prior error', () {
      expect(() => auth.clearError(), returnsNormally);
    });
  });
}
