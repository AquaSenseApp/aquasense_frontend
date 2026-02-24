import '../core/errors/api_exception.dart';
import '../core/network/api_endpoints.dart';
import '../core/network/dio_client.dart';
import '../models/user_model.dart';

/// Service class for all authentication-related HTTP calls.
///
/// Returns typed [UserModel] objects — providers and screens never
/// touch raw JSON or Dio directly.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _dio = DioClient.instance;

  // ── Login ──────────────────────────────────────────────────────────────────

  /// POST /api/users/login
  ///
  /// Response: { "message", "token", "userId" }
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );
      final data = res.data!;
      return UserModel(
        userId: data['userId'] as int?,
        email:  email,
        token:  data['token'] as String?,
        isEmailVerified: true, // server-side auth — no OTP needed on login
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
  Future<UserModel> register({
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
      return UserModel(
        userId:           data['userId']  as int?,
        email:            email,
        username:         username,
        fullName:         fullName,
        organizationType: organizationType,
        // Registration doesn't return a token — user must log in after OTP
        isEmailVerified:  false,
      );
    } catch (e) {
      throw extractApiException(e);
    }
  }
}
