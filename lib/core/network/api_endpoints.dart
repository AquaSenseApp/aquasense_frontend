/// All API endpoint paths.
///
/// [baseUrl] points to the running backend.
/// Every method on [ApiEndpoints] returns a full path string.
/// Screens and services import this class — no raw URL strings elsewhere.
class ApiEndpoints {
  ApiEndpoints._();

  /// Base URL of the AquaSense backend.
  /// IMPORTANT: Use HTTPS in production for secure communication.
  /// For local development, you may use http://localhost:5000
  /// but never deploy with HTTP to production.
  static const baseUrl = 'https://api.aquasense.com';

  // ── Auth ────────────────────────────────────────────────────────────────
  static const login    = '/api/users/login';
  static const register = '/api/users/register';

  // ── Sensors ─────────────────────────────────────────────────────────────
  static const registerSensor = '/api/sensors/register';

  /// GET all sensors for a user: /api/sensors/user/{userId}
  static String sensorsByUser(int userId) => '/api/sensors/user/$userId';

  /// GET analytics for a user: /api/sensors/analytics/{userId}
  static String analyticsForUser(int userId) => '/api/sensors/analytics/$userId';

  // ── Readings ─────────────────────────────────────────────────────────────
  static const uploadReading = '/api/readings/upload';

  // ── Alerts ──────────────────────────────────────────────────────────────
  /// GET all alerts for a user: /api/alerts/user/{userId}
  static String alertsByUser(int userId) => '/api/alerts/user/$userId';

  /// PATCH resolve an alert: /api/alerts/resolve/{alertId}
  static String resolveAlert(int alertId) => '/api/alerts/resolve/$alertId';
}
