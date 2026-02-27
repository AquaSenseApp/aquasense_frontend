import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../errors/api_exception.dart';
import 'api_endpoints.dart';

/// Singleton Dio HTTP client used by all service classes.
///
/// Responsibilities:
///   • Attaches the JWT token from SharedPreferences to every request
///     via [_AuthInterceptor].
///   • Converts Dio errors into typed [ApiException]s so callers never
///     need to import Dio themselves.
///   • Configures timeouts: 15 s connect, 20 s receive.
class DioClient {
  DioClient._();
// one single connection manager.
  static final DioClient instance = DioClient._();

  late final Dio _dio;
  bool _initialised = false;

  /// Must be called once in [main] before any service is used.
  void initialise() {
    if (_initialised) return;
    _dio = Dio(
      BaseOptions(
        baseUrl:        ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    // security guards that stand between your app and the internet.
    // The auth interceptor must be first to ensure the token is attached before any request is made.
    _dio.interceptors.add(_AuthInterceptor());
    _dio.interceptors.add(_RetryInterceptor(_dio));
    // error interceptor must be last to catch any errors from previous interceptors or the request itself.
    _dio.interceptors.add(_ErrorInterceptor());
    _initialised = true;
  }

  // ── Convenience methods ──────────────────────────────────────────────────

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.get<T>(path,
          queryParameters: queryParameters, options: options);

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Options? options,
  }) =>
      _dio.post<T>(path, data: data, options: options);

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Options? options,
  }) =>
      _dio.patch<T>(path, data: data, options: options);
}

// ─────────────────────────────────────────────────────────────────────────────
// Interceptors
// ─────────────────────────────────────────────────────────────────────────────

/// Reads the JWT from SharedPreferences and injects it as a Bearer token.
/// Skipped for login and register endpoints that don't require auth.
class _AuthInterceptor extends Interceptor {
  static const _skipPaths = [
    ApiEndpoints.login,
    ApiEndpoints.register,
  ];

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final needsAuth = !_skipPaths.any(
      (p) => options.path.endsWith(p),
    );

    if (needsAuth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('aquasense_token');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// Retry interceptor
// ─────────────────────────────────────────────────────────────────────────────

/// Retries a request once when the error is a connection timeout or a
/// 503 Service Unavailable — both symptoms of a Render cold-start.
///
/// Why one retry and not more?
///   If the server is genuinely down (not cold-starting), retrying more than
///   once wastes the user's time and battery.  One retry covers the
///   cold-start window; if it still fails, the user sees an error banner
///   and can manually retry via pull-to-refresh.
///
/// Why only timeout / 503?
///   Other errors (400 Bad Request, 401 Unauthorised, 404 Not Found) are
///   deterministic — retrying them would return the same error and confuse
///   the user by doubling the response time.
class _RetryInterceptor extends Interceptor {
  final Dio _dio;
  _RetryInterceptor(this._dio);

  static const _retryHeader = 'x-retry-attempt';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isAlreadyRetried =
        err.requestOptions.headers.containsKey(_retryHeader);
    final isRetryable = _shouldRetry(err);

    if (isRetryable && !isAlreadyRetried) {
      try {
        final options = err.requestOptions;
        options.headers[_retryHeader] = '1';
        final response = await _dio.fetch<dynamic>(options);
        return handler.resolve(response);
      } on DioException catch (retryErr) {
        return handler.next(retryErr);
      }
    }
    handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    if (err.type == DioExceptionType.connectionTimeout) return true;
    if (err.type == DioExceptionType.receiveTimeout)    return true;
    if (err.type == DioExceptionType.connectionError)   return true;
    final statusCode = err.response?.statusCode;
    if (statusCode == 503)                              return true;
    return false;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error interceptor
// ─────────────────────────────────────────────────────────────────────────────

/// Converts [DioException] into a typed [ApiException] so callers only
/// catch one exception type.
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;
    String message;

    if (response != null) {
      // Try to extract the server's own error message
      final data = response.data;
      if (data is Map) {
        message = (data['message'] ?? data['error'] ?? response.statusMessage)
            .toString();
      } else {
        message = response.statusMessage ?? 'Server error';
      }
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          response: response,
          error: ApiException(
            statusCode: response.statusCode,
            message:    message,
          ),
        ),
      );
    } else {
      // Network-level error — may be a Render cold-start timeout
      final isTimeout = err.type == DioExceptionType.connectionTimeout ||
          err.type == DioExceptionType.receiveTimeout;
      final msg = isTimeout
          ? 'Server is waking up — please wait a moment and try again.'
          : 'Network error. Please check your connection.';
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: ApiException(message: msg),
        ),
      );
    }
  }
}

/// Extracts an [ApiException] from a caught [DioException].
/// Call from service catch blocks: `throw extractApiException(e)`
ApiException extractApiException(Object e) {
  if (e is DioException && e.error is ApiException) {
    return e.error as ApiException;
  }
  return ApiException(message: e.toString());
}

