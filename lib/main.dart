import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/create_account_screen.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/email_verified_screen.dart';
import 'screens/home/home_screen.dart';

void main() {
  runApp(const AquaSenseApp());
}

class AquaSenseApp extends StatelessWidget {
  const AquaSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'AquaSense',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (_) => const SplashScreen(),
          AppRoutes.onboarding: (_) => const OnboardingScreen(),
          AppRoutes.createAccount: (_) => const CreateAccountScreen(),
          AppRoutes.signIn: (_) => const SignInScreen(),
          AppRoutes.emailVerified: (_) => const EmailVerifiedScreen(),
          AppRoutes.home: (_) => const HomeScreen(),
        },
      ),
    );
  }
}