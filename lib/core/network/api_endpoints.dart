/// All API endpoint paths.
///
/// [baseUrl] points to the live AquaSense backend on Render.
/// Every method returns a full path string — no raw URL strings exist
/// anywhere else in the codebase, so pointing to a different environment
/// (staging, local) requires changing exactly one line.
class ApiEndpoints {
  ApiEndpoints._();

  /// Production backend — hosted on Render.
  /// To develop locally, swap this for 'http://10.0.2.2:5000' (Android
  /// emulator) or 'http://localhost:5000' (iOS simulator).
  static const baseUrl = 'https://aquasense-ai-api.onrender.com';

  // ── Auth ─────────────────────────────────────────────────────────────────
  /// Step 1 of login — sends credentials, backend emails OTP. No token returned.
  static const login         = '/api/users/login';
  static const register      = '/api/users/register';
  /// Step 2 of login — submits email + OTP code, returns JWT token.
  static const verifyOtp     = '/api/users/verify-otp';
  static const forgotPassword = '/api/users/forgot-password';
  static const resetPassword  = '/api/users/reset-password';
  static const profile        = '/api/users/profile';

  // ── Sensors ──────────────────────────────────────────────────────────────
  static const registerSensor = '/api/sensors/register';

  /// GET all sensors for a user: /api/sensors/user/{userId}
  /// NOTE: api_key is excluded from this response by the backend (security).
  /// The apiKey is only available once at registration time.
  static String sensorsByUser(int userId) => '/api/sensors/user/$userId';

  /// GET analytics for ONE sensor: /api/sensors/analytics/{sensorId}
  /// Parameter is sensorId, NOT userId.
  static String analyticsForSensor(int sensorId) =>
      '/api/sensors/analytics/$sensorId';

  // ── Readings ─────────────────────────────────────────────────────────────
  static const uploadReading = '/api/readings/upload';

  // ── Alerts ───────────────────────────────────────────────────────────────
  /// GET all alerts for a user: /api/alerts/user/{userId}
  static String alertsByUser(int userId) => '/api/alerts/user/$userId';

  /// PATCH resolve an alert: /api/alerts/resolve/{alertId}
  static String resolveAlert(int alertId) => '/api/alerts/resolve/$alertId';
}
