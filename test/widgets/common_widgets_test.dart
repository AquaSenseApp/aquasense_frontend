import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aquasense/widgets/common/app_button.dart';
import 'package:aquasense/widgets/common/app_text_field.dart';
import 'package:aquasense/widgets/auth/google_sign_in_button.dart';
import 'package:aquasense/core/theme/app_theme.dart';

void main() {
  group('AppButton Widget', () {
    testWidgets('should display label text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: Scaffold(
            body: AppButton(
              label: 'Test Button',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
    });

    testWidgets('should call onPressed when tapped', (tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: Scaffold(
            body: AppButton(
              label: 'Test Button',
              onPressed: () {
                wasPressed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Test Button'));
      expect(wasPressed, true);
    });

    testWidgets('should be disabled when enabled is false', (tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: Scaffold(
            body: AppButton(
              label: 'Disabled Button',
              enabled: false,
              onPressed: () {
                wasPressed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Disabled Button'));
      expect(wasPressed, false);
    });

    testWidgets('should show loading indicator when isLoading is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: Scaffold(
            body: AppButton(
              label: 'Loading Button',
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      // Should find a CircularProgressIndicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should not show label when loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: Scaffold(
            body: AppButton(
              label: 'Loading Button',
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      // Label should not be visible when loading
      expect(find.text('Loading Button'), findsNothing);
    });

    testWidgets('should be disabled when loading', (tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: Scaffold(
            body: AppButton(
              label: 'Loading Button',
              isLoading: true,
              onPressed: () {
                wasPressed = true;
              },
            ),
          ),
        ),
      );

      // Try to tap the button - should not trigger onPressed
      await tester.tap(find.byType(ElevatedButton));
      expect(wasPressed, false);
    });
  });

  group('AppTextField Widget', () {
    testWidgets('should display hint text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: Scaffold(
            body: AppTextField(
              hint: 'Enter your email',
              controller: TextEditingController(),
            ),
          ),
        ),
      );

      expect(find.text('Enter your email'), findsOneWidget);
    });

    testWidgets('should accept text input', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: Scaffold(
            body: AppTextField(
              hint: 'Enter text',
              controller: controller,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Hello World');
      expect(controller.text, 'Hello World');
    });

    testWidgets('should show password field when isPassword is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: Scaffold(
            body: AppTextField(
              hint: 'Password',
              controller: TextEditingController(),
              isPassword: true,
            ),
          ),
        ),
      );

      // Find the TextField and check obscureText property
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, true);
    });

    testWidgets('should show keyboard type when specified', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: Scaffold(
            body: AppTextField(
              hint: 'Email',
              controller: TextEditingController(),
              keyboardType: TextInputType.emailAddress,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.keyboardType, TextInputType.emailAddress);
    });

    testWidgets('should call onChanged when text changes', (tester) async {
      String? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: Scaffold(
            body: AppTextField(
              hint: 'Type something',
              controller: TextEditingController(),
              onChanged: (value) {
                changedValue = value;
              },
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'New Text');
      expect(changedValue, 'New Text');
    });

    testWidgets('should show suffix icon for password field', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: Scaffold(
            body: AppTextField(
              hint: 'Password',
              controller: TextEditingController(),
              isPassword: true,
            ),
          ),
        ),
      );

      // Password fields should show visibility toggle icon
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('should toggle password visibility', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: Scaffold(
            body: AppTextField(
              hint: 'Password',
              controller: TextEditingController(text: 'secret'),
              isPassword: true,
            ),
          ),
        ),
      );

      // Initially should show visibility_off icon
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

      // Tap the toggle button
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();

      // After tap, should show visibility icon
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });
  });

  group('GoogleSignInButton Widget', () {
    testWidgets('should display label text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: Scaffold(
            body: GoogleSignInButton(
              label: 'Sign in with Google',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Sign in with Google'), findsOneWidget);
    });

    testWidgets('should call onTap when tapped', (tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: Scaffold(
            body: GoogleSignInButton(
              label: 'Sign in with Google',
              onTap: () {
                wasTapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(OutlinedButton));
      expect(wasTapped, true);
    });

    testWidgets('should show default label when not provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: Scaffold(
            body: GoogleSignInButton(
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Sign in with Google'), findsOneWidget);
    });

    testWidgets('should be disabled when isLoading is true', (tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: Scaffold(
            body: GoogleSignInButton(
              label: 'Signing in...',
              onTap: () {
                wasTapped = true;
              },
              isLoading: true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(OutlinedButton));
      expect(wasTapped, false);
    });

    testWidgets('should show loading indicator when isLoading is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: Scaffold(
            body: GoogleSignInButton(
              onTap: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      // Should find CircularProgressIndicator widgets
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });
  });
}
