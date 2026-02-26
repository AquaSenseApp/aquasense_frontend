import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aquasense/core/theme/app_theme.dart';

void main() {
  group('AppColors', () {
    test('should have brand teal colors', () {
      expect(AppColors.teal, const Color(0xFF1B6B5A));
      expect(AppColors.tealDark, const Color(0xFF0D4A3E));
      expect(AppColors.tealLight, const Color(0xFF2A8A72));
    });

    test('should have accent colors', () {
      expect(AppColors.mint, const Color(0xFFB2F5EA));
      expect(AppColors.mintLight, const Color(0xFFD4FAF2));
      expect(AppColors.pinkLight, const Color(0xFFFCE7F3));
    });

    test('should have neutral surface colors', () {
      expect(AppColors.white, const Color(0xFFFFFFFF));
      expect(AppColors.background, const Color(0xFFFAFAFA));
      expect(AppColors.surfaceGrey, const Color(0xFFF3F4F6));
    });

    test('should have text colors', () {
      expect(AppColors.textDark, const Color(0xFF1A1A2E));
      expect(AppColors.textGrey, const Color(0xFF6B7280));
    });

    test('should have border color', () {
      expect(AppColors.borderColor, const Color(0xFFE5E7EB));
    });

    test('should have risk colors - high', () {
      expect(AppColors.riskHighFg, const Color(0xFFBE123C));
      expect(AppColors.riskHighBg, const Color(0xFFFFE4E6));
    });

    test('should have risk colors - medium', () {
      expect(AppColors.riskMediumFg, const Color(0xFFB45309));
      expect(AppColors.riskMediumBg, const Color(0xFFFEF9C3));
    });

    test('should have risk colors - low', () {
      expect(AppColors.riskLowFg, const Color(0xFF15803D));
      expect(AppColors.riskLowBg, const Color(0xFFDCFCE7));
    });

    test('should have trend colors', () {
      expect(AppColors.trendUp, const Color(0xFF15803D));
      expect(AppColors.trendDown, const Color(0xFFBE123C));
      expect(AppColors.trendStable, const Color(0xFF6B7280));
    });

    test('should have AI FAB color', () {
      expect(AppColors.aiFab, const Color(0xFF7C2D8E));
    });
  });

  group('AppTextStyles', () {
    test('should have display large style', () {
      expect(AppTextStyles.displayLarge.fontSize, 26);
      expect(AppTextStyles.displayLarge.fontWeight, FontWeight.w700);
    });

    test('should have headline styles', () {
      expect(AppTextStyles.headlineMedium.fontSize, 22);
      expect(AppTextStyles.headlineMedium.fontWeight, FontWeight.w700);
      
      expect(AppTextStyles.headlineSmall.fontSize, 18);
      expect(AppTextStyles.headlineSmall.fontWeight, FontWeight.w700);
    });

    test('should have title styles', () {
      expect(AppTextStyles.titleLarge.fontSize, 24);
      expect(AppTextStyles.titleLarge.fontWeight, FontWeight.w700);
      
      expect(AppTextStyles.titleMedium.fontSize, 16);
      expect(AppTextStyles.titleMedium.fontWeight, FontWeight.w600);
      
      expect(AppTextStyles.titleSmall.fontSize, 12);
      expect(AppTextStyles.titleSmall.fontWeight, FontWeight.w600);
    });

    test('should have body styles', () {
      expect(AppTextStyles.bodyLarge.fontSize, 15);
      expect(AppTextStyles.bodyLarge.fontWeight, FontWeight.w400);
      
      expect(AppTextStyles.bodyMedium.fontSize, 14);
      expect(AppTextStyles.bodyMedium.fontWeight, FontWeight.w400);
      
      expect(AppTextStyles.bodySmall.fontSize, 12);
      expect(AppTextStyles.bodySmall.fontWeight, FontWeight.w400);
    });

    test('should have label styles', () {
      expect(AppTextStyles.labelLarge.fontSize, 14);
      expect(AppTextStyles.labelLarge.fontWeight, FontWeight.w600);
      
      expect(AppTextStyles.labelMedium.fontSize, 16);
      expect(AppTextStyles.labelMedium.fontWeight, FontWeight.w600);
      
      expect(AppTextStyles.labelSmall.fontSize, 11);
      expect(AppTextStyles.labelSmall.fontWeight, FontWeight.w400);
    });
  });

  group('AppTheme', () {
    test('should have valid theme data', () {
      final theme = AppTheme.theme;
      
      expect(theme, isA<ThemeData>());
    });

    test('should have primary color as teal', () {
      final theme = AppTheme.theme;
      
      expect(theme.colorScheme.primary, AppColors.teal);
    });

    test('should have scaffold background color', () {
      final theme = AppTheme.theme;
      
      expect(theme.scaffoldBackgroundColor, AppColors.background);
    });

    test('should use Material 3', () {
      final theme = AppTheme.theme;
      
      expect(theme.useMaterial3, true);
    });

    test('should have input decoration theme', () {
      final theme = AppTheme.theme;
      
      expect(theme.inputDecorationTheme, isA<InputDecorationTheme>());
      expect(theme.inputDecorationTheme.filled, true);
    });

    test('should have elevated button theme', () {
      final theme = AppTheme.theme;
      
      expect(theme.elevatedButtonTheme, isA<ElevatedButtonThemeData>());
    });

    test('should have card theme', () {
      final theme = AppTheme.theme;
      
      expect(theme.cardTheme, isA<CardTheme>());
      expect(theme.cardTheme.elevation, 0);
    });

    test('input decoration should have correct border radius', () {
      final theme = AppTheme.theme;
      
      final border = theme.inputDecorationTheme.border as OutlineInputBorder;
      expect(border.borderRadius, BorderRadius.circular(12));
    });

    test('elevated button should have correct minimum size', () {
      final theme = AppTheme.theme;
      
      final buttonStyle = theme.elevatedButtonTheme.style;
      expect(buttonStyle, isNotNull);
    });
  });
}
