import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const teal = Color(0xFF1B6B5A);
  static const tealDark = Color(0xFF0D4A3E);
  static const tealLight = Color(0xFF2A8A72);
  static const mint = Color(0xFFB2F5EA);
  static const mintLight = Color(0xFFD4FAF2);
  static const cyan = Color(0xFF7FFFEF);
  static const pink = Color(0xFFF472B6);
  static const pinkLight = Color(0xFFFCE7F3);
  static const white = Color(0xFFFFFFFF);
  static const background = Color(0xFFFAFAFA);
  static const textDark = Color(0xFF1A1A2E);
  static const textGrey = Color(0xFF6B7280);
  static const borderColor = Color(0xFFE5E7EB);
  static const checkboxFill = Color(0xFFFFF3E0);
  static const dotPurple = Color(0xFF7C3AED);
  static const dotGreen = Color(0xFF10B981);
  static const dotMaroon = Color(0xFF7F1D1D);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.teal),
        scaffoldBackgroundColor: AppColors.white,
        textTheme: GoogleFonts.dmSansTextTheme(),
        useMaterial3: true,
      );
}