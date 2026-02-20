import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../core/constants/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/onboarding_model.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/onboarding_illustration.dart';
// New imports for the extracted widgets
import '../../widgets/common/app_logo.dart'; 
import '../../widgets/common/app_skip_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleSkip() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.createAccount);
  }

  void _next(OnboardingProvider provider) {
    if (provider.canGoNext()) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _handleSkip();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OnboardingProvider(totalPages: onboardingPages.length),
      child: Consumer<OnboardingProvider>(
        builder: (context, provider, _) {
          final page = onboardingPages[provider.currentPage];
          final isLast = page.isLast;

          return Scaffold(
            backgroundColor: AppColors.white,
            body: SafeArea(
              child: Column(
                children: [
                  // Extracted Skip Button
                  SkipButton(onTap: _handleSkip),

                  const Expanded(
                    flex: 5,
                    child: OnboardingIllustration(),
                  ),

                  Expanded(
                    flex: 4,
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: provider.setPage,
                      itemCount: onboardingPages.length,
                      itemBuilder: (context, index) {
                        final p = onboardingPages[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Column(
                            children: [
                              Text(
                                p.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                p.description,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textGrey,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  _buildBottomNavigation(provider, isLast),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomNavigation(OnboardingProvider provider, bool isLast) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: isLast 
        ? Column(
            children: [
              AppButton(
                label: 'Get Started',
                onPressed: () => _next(provider),
              ),
              const SizedBox(height: 16),
              _signInLink(context),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SmoothPageIndicator(
                controller: _pageController,
                count: onboardingPages.length,
                effect: ExpandingDotsEffect(
                  activeDotColor: AppColors.teal,
                  dotColor: AppColors.borderColor,
                  dotHeight: 8,
                  dotWidth: 8,
                ),
              ),
              GestureDetector(
                onTap: () => _next(provider),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.cyan,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chevron_right, color: AppColors.textDark),
                ),
              ),
            ],
          ),
    );
  }

  Widget _signInLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Already have an account? ', style: TextStyle(color: AppColors.textGrey, fontSize: 14)),
        GestureDetector(
          onTap: () => Navigator.of(context).pushReplacementNamed(AppRoutes.signIn),
          child: const Text(
            'Sign in',
            style: TextStyle(color: AppColors.teal, fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}