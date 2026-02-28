import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/errors/api_exception.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/google_auth_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Pref keys
// ─────────────────────────────────────────────────────────────────────────────

class _PrefKeys {
  _PrefKeys._();
  static const userJson   = 'aquasense_user';
  static const token      = 'aquasense_token';
  static const rememberMe = 'aquasense_remember_me';
  static const verified   = 'aquasense_email_verified';
}

// ─────────────────────────────────────────────────────────────────────────────
// Auth status
// ─────────────────────────────────────────────────────────────────────────────

enum AuthStatus {
  initial,
  loading,
  /// Credentials accepted — backend has emailed an OTP. Waiting for user to
  /// enter the 6-digit code from their inbox.
  pendingVerification,
  authenticated,
  error,
}

// ─────────────────────────────────────────────────────────────────────────────
// AuthProvider
// ─────────────────────────────────────────────────────────────────────────────

/// Manages auth state and connects to the real API via [AuthService].
///
/// Login is a two-step flow:
///   1. [signIn]     → POST /api/users/login     → backend sends OTP to email
///   2. [verifyOtp]  → POST /api/users/verify-otp → validates code, stores JWT
///
/// Registration:
///   [createAccount] → POST /api/users/register → account created, no OTP sent
///   After success the user is redirected to [SignInScreen] where login starts.
///
/// SharedPreferences keys written:
///   • [_PrefKeys.userJson]   — full [UserModel] JSON for session restore
///   • [_PrefKeys.token]      — JWT read by [DioClient._AuthInterceptor]
///   • [_PrefKeys.verified]   — bool, true once OTP confirmed
///   • [_PrefKeys.rememberMe] — bool, true if user opted in
class AuthProvider extends ChangeNotifier {
  AuthStatus _status       = AuthStatus.initial;
  UserModel? _user;
  String?    _errorMessage;
  String?    _pendingEmail;
  bool       _rememberMe   = false;

  AuthStatus get status               => _status;
  UserModel? get user                 => _user;
  String?    get errorMessage         => _errorMessage;
  String?    get pendingEmail         => _pendingEmail;
  bool       get isAuthenticated      => _status == AuthStatus.authenticated;
  bool       get isPendingVerification => _status == AuthStatus.pendingVerification;

  // ── Session restore ──────────────────────────────────────────────────────

  /// Reads SharedPreferences on cold start.
  /// Returns true and sets status = authenticated if a valid session is found.
  Future<bool> restoreSession() async {
    final prefs    = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_PrefKeys.userJson);
    if (userJson == null) return false;
    try {
      final user = UserModel.fromJsonString(userJson);
      if (user.isEmailVerified && user.token != null) {
        _user   = user;
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }
    } catch (_) {
      await prefs.clear();
    }
    return false;
  }

  // ── Create account ───────────────────────────────────────────────────────

  /// POST /api/users/register
  ///
  /// On success: returns true — screen must navigate to [SignInScreen].
  /// Registration does NOT send an OTP and does NOT authenticate the user.
  /// The user must then sign in, which triggers the OTP email from the backend.
  Future<bool> createAccount({
    required String username,
    required String fullName,
    required String email,
    required String password,
    required String organizationType,
  }) async {
    if (email.isEmpty || password.isEmpty || username.isEmpty) {
      _setError('Please fill in all fields');
      return false;
    }
    _setLoading();
    try {
      await AuthService.instance.register(
        username:         username,
        fullName:         fullName,
        email:            email,
        password:         password,
        organizationType: organizationType,
      );
      // Registration succeeded — status goes back to initial so the screen
      // can navigate to SignInScreen without interference.
      _status = AuthStatus.initial;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.displayMessage);
      return false;
    }
  }

  // ── Sign in (Step 1) ─────────────────────────────────────────────────────

  /// POST /api/users/login
  ///
  /// Validates credentials. On success the backend sends a 6-digit OTP to
  /// the user's email inbox and this method transitions to
  /// [AuthStatus.pendingVerification]. No token is returned at this stage.
  ///
  /// The screen must then push [AppRoutes.emailVerification].
  Future<bool> signIn({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    if (email.isEmpty || password.isEmpty) {
      _setError('Please fill in all fields');
      return false;
    }
    _setLoading();
    try {
      await AuthService.instance.login(email: email, password: password);
      _pendingEmail = email.trim();
      _rememberMe   = rememberMe;
      _status       = AuthStatus.pendingVerification;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.displayMessage);
      return false;
    }
  }

  // ── OTP verification (Step 2) ─────────────────────────────────────────────

  /// POST /api/users/verify-otp
  ///
  /// Sends { email, otp } to the backend. The OTP is the 6-digit code the
  /// user received in their inbox — it is NOT locally generated or compared.
  ///
  /// On success the backend returns a JWT and full user object. The session
  /// is persisted to SharedPreferences and status transitions to authenticated.
 // ── OTP verification (Step 2) ─────────────────────────────────────────────

  Future<bool> verifyOtp(String enteredCode) async {
    final email = _pendingEmail;
    if (email == null || email.isEmpty) {
      _setError('Session expired. Please sign in again.');
      return false;
    }
    _setLoading();
    
    try {
      // 1. Call the service
      final user = await AuthService.instance.verifyOtp(
        email: email,
        otp: enteredCode.trim(),
      );

      // 2. Prepare the verified user model
      final verified = user.copyWith(
        isEmailVerified: true,
        rememberMe: _rememberMe,
      );

      // 3. SECURE THE SESSION (This fixes your Postman 'Unauthorized' issue too)
      final prefs = await SharedPreferences.getInstance();
      
      if (verified.token != null) {
        // This is the token that DioClient needs for /my-sensors
        await prefs.setString(_PrefKeys.token, verified.token!);
      }
      
      await prefs.setString(_PrefKeys.userJson, verified.toJsonString());
      await prefs.setBool(_PrefKeys.verified, true);
      
      if (_rememberMe) {
        await prefs.setBool(_PrefKeys.rememberMe, true);
      }

      // 4. Update UI State
      _user = verified;
      _pendingEmail = null;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
      
    } on ApiException catch (e) {
      // If the backend isn't updated yet, this will still throw "Invalid OTP"
      _setError(e.displayMessage);
      return false;
    }
  }

  // ── Resend OTP ───────────────────────────────────────────────────────────

  /// Re-calls POST /api/users/login to trigger a fresh OTP email.
  ///
  /// We don't store the password after step 1, so we re-trigger via
  /// [ApiEndpoints.resendOtpForEmail] which is a lightweight endpoint
  /// that only needs the email.
  ///
  /// NOTE: the backend does not have a dedicated resend endpoint — calling
  /// /login again with just the email would require the password. Instead
  /// we show a message instructing the user to go back and sign in again
  /// if the OTP has expired. For the common case (OTP arrived but user
  /// typed it wrong once), the same OTP is still valid for 10 minutes.
  Future<void> resendOtp() async {
    // The OTP is still valid on the backend for 10 minutes from when /login
    // was called. Tell the user to check their spam folder or re-enter.
    // If they need a genuinely new code they must go back and sign in again.
    notifyListeners();
  }

  // ── Forgot password ──────────────────────────────────────────────────────

  /// POST /api/users/forgot-password
  ///
  /// Always returns true (backend never reveals whether the email exists).
  /// On success the user should see a "check your inbox" confirmation.
  Future<bool> forgotPassword({required String email}) async {
    if (email.isEmpty) {
      _setError('Please enter your email address');
      return false;
    }
    _setLoading();
    try {
      await AuthService.instance.forgotPassword(email: email);
      _status = AuthStatus.initial;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.displayMessage);
      return false;
    }
  }

  // ── Reset password ───────────────────────────────────────────────────────

  /// POST /api/users/reset-password
  ///
  /// [token] is the raw token from the reset link query parameter.
  /// [newPassword] must be at least 6 characters.
  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    if (token.isEmpty || newPassword.isEmpty) {
      _setError('Token and password are required');
      return false;
    }
    if (newPassword.length < 6) {
      _setError('Password must be at least 6 characters');
      return false;
    }
    _setLoading();
    try {
      await AuthService.instance.resetPassword(
        token:       token,
        newPassword: newPassword,
      );
      _status = AuthStatus.initial;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.displayMessage);
      return false;
    }
  }

  // ── Google sign-in / sign-up ─────────────────────────────────────────────

  /// Triggers the Google account picker via [GoogleAuthService].
  ///
  /// On success the [UserModel] built from the Google profile is persisted
  /// to SharedPreferences and status transitions to [AuthStatus.authenticated].
  /// No OTP is required — Google has already verified the email address.
  Future<bool> signInWithGoogle() async {
    _setLoading();
    try {
      final result = await GoogleAuthService.instance.signIn();
      final user   = result.user;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_PrefKeys.token,    user.token ?? '');
      await prefs.setString(_PrefKeys.userJson, user.toJsonString());
      await prefs.setBool(_PrefKeys.verified,   true);
      await prefs.setBool(_PrefKeys.rememberMe, true);

      _user   = user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on GoogleSignInException catch (e) {
      if (e.message.contains('cancelled')) {
        _status = AuthStatus.initial;
        _errorMessage = null;
        notifyListeners();
      } else {
        _setError(e.message);
      }
      return false;
    } catch (e) {
      _setError('Google sign-in failed. Please try again.');
      return false;
    }
  }

  // ── Sign out ─────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_PrefKeys.userJson);
    await prefs.remove(_PrefKeys.token);
    await prefs.remove(_PrefKeys.verified);
    await prefs.remove(_PrefKeys.rememberMe);
    await GoogleAuthService.instance.signOut();
    _user         = null;
    _pendingEmail = null;
    _rememberMe   = false;
    _status       = AuthStatus.initial;
    notifyListeners();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  void clearError() { _errorMessage = null; notifyListeners(); }

  void _setLoading() {
    _status       = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _status       = AuthStatus.error;
    _errorMessage = msg;
    notifyListeners();
  }

  // ── Test seeding (visibleForTesting) ────────────────────────────────────

  @visibleForTesting
  void setPendingStateForTest({
    required String    email,
    required UserModel user,
  }) {
    _pendingEmail = email;
    _user         = user;
    _status       = AuthStatus.pendingVerification;
    notifyListeners();
  }
}
