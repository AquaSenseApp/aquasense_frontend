/// Typed exception thrown by service classes when an API call fails.
///
/// [statusCode] is the HTTP status (null for network/timeout errors).
/// [message] is the human-readable error extracted from the response body
/// or a generic fallback message.
class ApiException implements Exception {
  final int?   statusCode;
  final String message;

  const ApiException({
    this.statusCode,
    required this.message,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';

  /// Whether the failure was a network-level error (no response received).
  bool get isNetworkError => statusCode == null;

  /// Whether the server returned a 401 Unauthorised response.
  bool get isUnauthorised => statusCode == 401;

  /// Human-readable label safe to show in a UI snackbar or error text.
  String get displayMessage {
    if (isNetworkError) return 'No internet connection. Check your network.';
    if (isUnauthorised) return 'Session expired. Please sign in again.';
    return message;
  }
}
