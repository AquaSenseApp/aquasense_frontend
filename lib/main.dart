import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'providers/alert_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/sensor_provider.dart';
import 'repositories/sensor_repository.dart';
import 'screens/ai_chat/ai_chat_screen.dart';
import 'screens/auth/create_account_screen.dart';
import 'screens/auth/email_verified_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/home/main_shell.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/sensors/ai_advisory_screen.dart';
import 'screens/sensors/sensor_detail_screen.dart';
import 'screens/splash/splash_screen.dart';

void main() => runApp(const AquaSenseApp());

class AquaSenseApp extends StatelessWidget {
  const AquaSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // SensorProvider — swap MockSensorRepository for a real one freely
        ChangeNotifierProvider(
          create: (_) => SensorProvider(MockSensorRepository()),
        ),
        // AlertProvider — owns the alert list, filter, and search query
        ChangeNotifierProvider(create: (_) => AlertProvider()),
        // ChatProvider is NOT global — it is scoped to AiChatScreen via
        // ChangeNotifierProvider inside that screen so each session is fresh.
      ],
      child: MaterialApp(
        title:                      'AquaSense',
        debugShowCheckedModeBanner: false,
        theme:                      AppTheme.theme,
        initialRoute:               AppRoutes.splash,
        routes: {
          AppRoutes.splash:         (_) => const SplashScreen(),
          AppRoutes.onboarding:     (_) => const OnboardingScreen(),
          AppRoutes.createAccount:  (_) => const CreateAccountScreen(),
          AppRoutes.signIn:         (_) => const SignInScreen(),
          AppRoutes.forgotPassword: (_) => const ForgotPasswordScreen(),
          AppRoutes.emailVerified:  (_) => const EmailVerifiedScreen(),
          AppRoutes.home:           (_) => const MainShell(),
          AppRoutes.sensorDetail:   (_) => const SensorDetailScreen(),
          AppRoutes.aiAdvisory:     (_) => const AiAdvisoryScreen(),
          AppRoutes.aiChat:         (_) => const AiChatScreen(),
        },
      ),
    );
  }
}
