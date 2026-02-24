import 'package:flutter/material.dart';

/// Manages which onboarding page is currently visible.
/// Consumed by [OnboardingScreen] via [Consumer].
class OnboardingProvider extends ChangeNotifier {
  final int totalPages;
  int _currentPage = 0;

  OnboardingProvider({required this.totalPages});

  int get currentPage => _currentPage;

  /// Returns true when there is a next page to navigate to.
  bool canGoNext() => _currentPage < totalPages - 1;

  /// Called by the [PageView] whenever the user swipes.
  void setPage(int page) {
    _currentPage = page;
    notifyListeners();
  }
}
