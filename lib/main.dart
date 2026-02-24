import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_routes.dart';
import 'core/network/dio_client.dart';
import 'core/theme/app_theme.dart';
import 'providers/alert_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/sensor_provider.dart';
import 'screens/ai_chat/ai_chat_screen.dart';
import 'screens/auth/create_account_screen.dart';
import 'screens/auth/email_verification_screen.dart';
import 'screens/auth/email_verified_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/home/main_shell.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/readings/reading_upload_screen.dart';
import 'screens/sensors/ai_advisory_screen.dart';
import 'screens/sensors/sensor_detail_screen.dart';
import 'screens/splash/splash_screen.dart';

/// App entry point.
///
/// Initialises [DioClient] before [runApp] so the interceptors are in place
/// before any service makes its first call.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Configure Dio singleton — must happen before any service call.
  DioClient.instance.initialise();
  runApp(const AquaSenseApp());
}

class AquaSenseApp extends StatelessWidget {
  const AquaSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // AuthProvider — no dependencies; manages JWT + SharedPreferences.
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // SensorProvider — depends on the authenticated user for userId.
        // Constructed via ProxyProvider so it always gets the latest UserModel
        // when auth state changes (e.g. after login or session restore).
        ChangeNotifierProxyProvider<AuthProvider, SensorProvider>(
          create:  (ctx) => SensorProvider(ctx.read<AuthProvider>().user),
          update:  (_, auth, previous) =>
              previous!..updateUser(auth.user),
        ),

        // AlertProvider — depends on userId to fetch /api/alerts/user/{id}.
        ChangeNotifierProxyProvider<AuthProvider, AlertProvider>(
          create:  (ctx) => AlertProvider(ctx.read<AuthProvider>().user),
          update:  (_, auth, previous) =>
              previous!..updateUser(auth.user),
        ),
      ],
      child: MaterialApp(
        title:                      'AquaSense',
        debugShowCheckedModeBanner: false,
        theme:                      AppTheme.theme,
        initialRoute:               AppRoutes.splash,
        routes: {
          AppRoutes.splash:            (_) => const SplashScreen(),
          AppRoutes.onboarding:        (_) => const OnboardingScreen(),
          AppRoutes.createAccount:     (_) => const CreateAccountScreen(),
          AppRoutes.signIn:            (_) => const SignInScreen(),
          AppRoutes.forgotPassword:    (_) => const ForgotPasswordScreen(),
          AppRoutes.emailVerification: (_) => const EmailVerificationScreen(),
          AppRoutes.emailVerified:     (_) => const EmailVerifiedScreen(),
          AppRoutes.home:              (_) => const MainShell(),
          AppRoutes.sensorDetail:      (_) => const SensorDetailScreen(),
          AppRoutes.aiAdvisory:        (_) => const AiAdvisoryScreen(),
          AppRoutes.aiChat:            (_) => const AiChatScreen(),
          // Manual reading upload — argument: SensorModel
          AppRoutes.uploadReading:     (_) => const ReadingUploadScreen(),
        },
      ),
    );
  }
}