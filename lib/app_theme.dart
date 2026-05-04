import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Background & Surface
  static const background = Color(0xFFF9F9FF);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF1F3FE);
  static const surfaceContainer = Color(0xFFECEDF9);
  static const surfaceContainerHigh = Color(0xFFE6E8F3);
  static const surfaceContainerHighest = Color(0xFFE0E2ED);

  // Text
  static const onSurface = Color(0xFF181C23);
  static const onSurfaceVariant = Color(0xFF414755);
  static const outline = Color(0xFF717786);
  static const outlineVariant = Color(0xFFC1C6D7);

  // Primary - Object Detection / Brand Blue
  static const primary = Color(0xFF0058BC);
  static const primaryContainer = Color(0xFF0070EB);
  static const onPrimary = Color(0xFFFFFFFF);
  static const inversePrimary = Color(0xFFADC6FF);

  // Secondary - Path Navigation Green
  static const secondary = Color(0xFF006E2D);
  static const secondaryContainer = Color(0xFF7CF994);
  static const onSecondary = Color(0xFFFFFFFF);

  // Tertiary - Environment Analysis Amber
  static const tertiary = Color(0xFF9E3D00);
  static const tertiaryContainer = Color(0xFFC64F00);
  static const onTertiary = Color(0xFFFFFFFF);

  // Face Detection - Violet (custom)
  static const face = Color(0xFF7C3AED);
  static const faceContainer = Color(0xFFEDE9FE);
  static const onFace = Color(0xFFFFFFFF);

  // Status
  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onError = Color(0xFFFFFFFF);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimary,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.secondary,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onTertiary,
        tertiaryContainer: AppColors.tertiaryContainer,
        onTertiaryContainer: AppColors.onTertiary,
        error: AppColors.error,
        onError: AppColors.onError,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: AppColors.error,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        surfaceContainerHighest: AppColors.surfaceContainerHighest,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.lexendTextTheme(
        const TextTheme(
          displayLarge: TextStyle(fontSize: 40, fontWeight: FontWeight.w700, height: 1.2),
          displayMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, height: 1.2),
          bodyLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, height: 1.5),
          bodyMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w400, height: 1.5),
          labelLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.0),
          labelMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.0),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: 'Lexend',
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
        iconTheme: IconThemeData(color: AppColors.primary, size: 32),
        toolbarHeight: 80,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.outlineVariant, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(64, 64),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          textStyle: const TextStyle(fontFamily: 'Lexend', fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
