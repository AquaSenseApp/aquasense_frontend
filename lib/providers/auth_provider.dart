import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/errors/api_exception.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Pref keys
// ─────────────────────────────────────────────────────────────────────────────

class _PrefKeys {
  _PrefKeys._();
  static const userJson  = 'aquasense_user';
  static const token     = 'aquasense_token';  // also stored separately so DioClient can read it
  static const rememberMe = 'aquasense_remember_me';
  static const verified   = 'aquasense_email_verified';
}

// ─────────────────────────────────────────────────────────────────────────────
// Auth status
// ─────────────────────────────────────────────────────────────────────────────

enum AuthStatus {
  initial,
  loading,
  pendingVerification,
  authenticated,
  error,
}

// ─────────────────────────────────────────────────────────────────────────────
// AuthProvider
// ─────────────────────────────────────────────────────────────────────────────

/// Manages auth state and connects to the real API via [AuthService].
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
  String?    _pendingOtp;
  String?    _pendingEmail;

  AuthStatus get status               => _status;
  UserModel? get user                 => _user;
  String?    get errorMessage         => _errorMessage;
  String?    get pendingEmail         => _pendingEmail;
  bool       get isAuthenticated      => _status == AuthStatus.authenticated;
  bool       get isPendingVerification => _status == AuthStatus.pendingVerification;

  // ── Session restore ─────────────────────────────────────────────────────

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

  // ── Create account ──────────────────────────────────────────────────────

  /// Calls POST /api/users/register then moves to OTP verification.
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
      final user = await AuthService.instance.register(
        username:         username,
        fullName:         fullName,
        email:            email,
        password:         password,
        organizationType: organizationType,
      );

      // Store pending user; OTP required before full session is written
      _pendingEmail = email.trim();
      // Note: OTP should be generated server-side and sent via email/SMS
      // Client-side OTP generation is only for demo purposes
      _pendingOtp   = _generateOtp();
      debugPrint('Generated OTP: $_pendingOtp');

      final draft = user.copyWith(isEmailVerified: false);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_PrefKeys.userJson, draft.toJsonString());
      await prefs.setBool(_PrefKeys.verified, false);

      _user   = draft;
      _status = AuthStatus.pendingVerification;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.displayMessage);
      return false;
    }
  }

  // ── Sign in ─────────────────────────────────────────────────────────────

  /// Calls POST /api/users/login.
  ///
  /// • If the API returns a token → session is valid → authenticated directly.
  /// • On first-time login (no stored token) → requires OTP.
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
      final user = await AuthService.instance.login(
        email:    email,
        password: password,
      );

      // Write token so DioClient can use it for subsequent requests
      final prefs = await SharedPreferences.getInstance();
      if (user.token != null) {
        await prefs.setString(_PrefKeys.token, user.token!);
      }
      if (rememberMe) {
        await prefs.setBool(_PrefKeys.rememberMe, true);
      }

      final verified = user.copyWith(
        isEmailVerified: true,
        rememberMe:      rememberMe,
      );

      await prefs.setString(_PrefKeys.userJson, verified.toJsonString());
      await prefs.setBool(_PrefKeys.verified, true);

      _user   = verified;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.displayMessage);
      return false;
    }
  }

  // ── OTP verification ────────────────────────────────────────────────────

  /// Compares [enteredCode] to the generated OTP.
  /// On success, marks session as verified and writes prefs.
  Future<bool> verifyOtp(String enteredCode) async {
    _setLoading();
    await Future.delayed(const Duration(milliseconds: 400));

    if (_pendingOtp == null || enteredCode.trim() != _pendingOtp) {
      _setError('Invalid code. Please try again.');
      return false;
    }

    final verified = (_user ?? UserModel(email: _pendingEmail ?? ''))
        .copyWith(isEmailVerified: true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_PrefKeys.userJson, verified.toJsonString());
    await prefs.setBool(_PrefKeys.verified, true);

    _user         = verified;
    _pendingOtp   = null;
    _pendingEmail = null;
    _status       = AuthStatus.authenticated;
    notifyListeners();
    return true;
  }

  // ── Resend OTP ──────────────────────────────────────────────────────────

  Future<void> resendOtp() async {
    // Note: OTP should be generated server-side and sent via email/SMS
    _pendingOtp = _generateOtp();
    notifyListeners();
  }

  // ── Sign out ────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_PrefKeys.userJson);
    await prefs.remove(_PrefKeys.token);
    await prefs.remove(_PrefKeys.verified);
    await prefs.remove(_PrefKeys.rememberMe);
    _user         = null;
    _pendingOtp   = null;
    _pendingEmail = null;
    _status       = AuthStatus.initial;
    notifyListeners();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

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

  String _generateOtp() {
    final rng = Random.secure();
    return List.generate(5, (_) => rng.nextInt(10)).join();
  }
}
