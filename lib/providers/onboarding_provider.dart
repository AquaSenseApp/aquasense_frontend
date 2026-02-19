import 'package:flutter/material.dart';

class OnboardingProvider extends ChangeNotifier {
  int _currentPage = 0;
  final int totalPages;

  OnboardingProvider({this.totalPages = 3});

  int get currentPage => _currentPage;

  void setPage(int page) {
    _currentPage = page; // Update this if you add/remove onboarding pages
    notifyListeners();
  }

  bool canGoNext() {
    return _currentPage < totalPages - 1;
  }

  void nextPage() {
    if (canGoNext()) {
      _currentPage++;
      notifyListeners();
    }
  }
}