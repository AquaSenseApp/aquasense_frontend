import 'package:flutter/material.dart';
import '../core/errors/api_exception.dart';
import '../services/reading_service.dart';

/// Manages the state for a single reading upload operation.
///
/// Scoped to [ReadingUploadScreen] via [ChangeNotifierProvider] — a fresh
/// instance is created each time the screen opens so state never leaks
/// between sessions.
class ReadingProvider extends ChangeNotifier {
  bool                  _isLoading  = false;
  ReadingUploadResponse? _result;
  String?               _errorMessage;

  bool                   get isLoading    => _isLoading;
  ReadingUploadResponse? get result        => _result;
  String?                get errorMessage => _errorMessage;

  /// Calls POST /api/readings/upload with the supplied [request].
  ///
  /// On success [result] is set and [errorMessage] is null.
  /// On failure [errorMessage] is set and [result] is null.
  Future<void> upload(ReadingUploadRequest request) async {
    _isLoading    = true;
    _errorMessage = null;
    _result       = null;
    notifyListeners();

    try {
      _result = await ReadingService.instance.upload(request);
    } on ApiException catch (e) {
      _errorMessage = e.displayMessage;
    } catch (e) {
      _errorMessage = 'Unexpected error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clears previous result so the user can re-enter values.
  void reset() {
    _result       = null;
    _errorMessage = null;
    notifyListeners();
  }
}
