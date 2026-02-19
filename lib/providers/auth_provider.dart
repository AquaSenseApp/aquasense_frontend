import 'package:flutter/material.dart';
import '../models/user_model.dart';

enum AuthStatus { initial, loading, authenticated, error }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<bool> createAccount({
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    // Simulate success
    _user = UserModel(email: email, isEmailVerified: true);
    _status = AuthStatus.authenticated;
    notifyListeners();
    return true;
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (email.isEmpty || password.isEmpty) {
      _status = AuthStatus.error;
      _errorMessage = 'Please fill in all fields';
      notifyListeners();
      return false;
    }

    _user = UserModel(email: email, isEmailVerified: true);
    _status = AuthStatus.authenticated;
    notifyListeners();
    return true;
  }

  void signOut() {
    _user = null;
    _status = AuthStatus.initial;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}