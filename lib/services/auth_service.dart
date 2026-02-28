import '../core/errors/api_exception.dart';
import '../core/network/api_endpoints.dart';
import '../core/network/dio_client.dart';
import '../models/user_model.dart';

/// Service class for all authentication-related HTTP calls.
///
/// The login flow is TWO steps:
///   1. [login]     → POST /api/users/login     → backend emails 6-digit OTP, returns no token
///   2. [verifyOtp] → POST /api/users/verify-otp → validates OTP, returns JWT + user object
///
/// Returns typed [UserModel] objects — providers and screens never
/// touch raw JSON or Dio directly.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _dio = DioClient.instance;

  // ── Step 1: Login (triggers OTP email) ────────────────────────────────────

  /// POST /api/users/login
  ///
  /// Sends credentials. Backend validates, generates a 6-digit OTP,
  /// emails it, and returns:
  ///   { "message": "OTP sent to <email>. Check your inbox." }
  ///
  /// No token is returned at this step. Callers must proceed to [verifyOtp].
  /// Returns the email string on success so [AuthProvider] can store it
  /// as [AuthProvider.pendingEmail] for the OTP screen to display.
  Future<String> login({
    required String email,
    required String password,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );
      // Response body is just { message } — we only care that the call succeeded.
      // Return the email so AuthProvider can store it for step 2.
      return email.trim();
    } catch (e) {
      throw extractApiException(e);
    }
  }

  // ── Step 2: Verify OTP → receive JWT ─────────────────────────────────────

  /// POST /api/users/verify-otp
  ///
  /// Body:     { "email": <email>, "otp": <6-digit code from email> }
  /// Response: { "message", "token", "user": { id, username, email, organization_type } }
  ///
  /// Returns a fully-authenticated [UserModel] with token and userId.
  Future<UserModel> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      print('🔐 DEBUG: Sending verify-otp | email=$email | otp=$otp');
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.verifyOtp,
        data: {'email': email, 'otp': otp},
      );
      print('✅ DEBUG: verify-otp response = ${res.data}');

      final data = res.data!;
      final user = data['user'] as Map<String, dynamic>;
      return UserModel(
        userId:           user['id']                as int?,
        email:            user['email']             as String,
        username:         user['username']          as String?,
        organizationType: user['organization_type'] as String?,
        token:            data['token']             as String?,
        isEmailVerified:  true,
        rememberMe:       false,
      );
    } catch (e) {
      throw extractApiException(e);
    }
  }

  // ── Register ───────────────────────────────────────────────────────────────

  /// POST /api/users/register
  ///
  /// Body:     { username, full_name, email, password, organization_type }
  /// Response: { "message", "userId" }
  ///
  /// Registration does NOT send an OTP and does NOT return a token.
  /// After success the user must log in, which triggers the OTP email.
  Future<int?> register({
    required String username,
    required String fullName,
    required String email,
    required String password,
    required String organizationType,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.register,
        data: {
          'username':          username,
          'full_name':         fullName,
          'email':             email,
          'password':          password,
          'organization_type': organizationType,
        },
      );
      final data = res.data!;
      return (data['userId'] ?? data['id']) as int?;
    } catch (e) {
      throw extractApiException(e);
    }
  }

  // ── Forgot password ────────────────────────────────────────────────────────

  /// POST /api/users/forgot-password
  ///
  /// Body:     { "email" }
  /// Response: { "message" }  (always 200 — backend doesn't reveal if email exists)
  ///
  /// On success the backend sends a reset link to the email (if it exists).
  Future<void> forgotPassword({required String email}) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.forgotPassword,
        data: {'email': email.trim()},
      );
    } catch (e) {
      throw extractApiException(e);
    }
  }

  // ── Reset password ─────────────────────────────────────────────────────────

  /// POST /api/users/reset-password
  ///
  /// Body:     { "token": <raw token from URL>, "newPassword": <new password> }
  /// Response: { "message": "Password reset successfully. You can now log in." }
  ///
  /// [token] comes from the reset link query parameter (?token=...).
  /// [newPassword] must be at least 6 characters.
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.resetPassword,
        data: {'token': token, 'newPassword': newPassword},
      );
    } catch (e) {
      throw extractApiException(e);
    }
  }
}
