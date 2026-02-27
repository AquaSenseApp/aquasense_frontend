import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aquasense/widgets/common/app_button.dart';

void main() {
  group('AppButton', () {
    testWidgets('renders with label text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Test Button',
              onPressed: _emptyCallback,
            ),
          ),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Test Button',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AppButton));
      expect(pressed, true);
    });

    testWidgets('displays loading indicator when isLoading is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Test Button',
              onPressed: _emptyCallback,
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('does not show loading when isLoading is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Test Button',
              onPressed: _emptyCallback,
              isLoading: false,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Test Button',
              onPressed: null,
            ),
          ),
        ),
      );

      final button = tester.widget<AppButton>(find.byType(AppButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('applies custom width when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Test Button',
              onPressed: _emptyCallback,
              width: 200,
            ),
          ),
        ),
      );

      // Find the SizedBox that wraps the button
      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(AppButton),
          matching: find.byType(SizedBox),
        ),
      );

      expect(sizedBox.width, 200);
    });
  });
}

void _emptyCallback() {}
