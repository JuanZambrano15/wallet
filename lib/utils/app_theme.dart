import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF004F39); // Verde bosque
  static const Color accent = Color(
    0xFFFFFFCA,
  ); // Crema — texto principal y highlights
  static const Color background = Color(0xFF151613); // Fondo casi negro
  static const Color surface = Color(
    0xFF1F2220,
  ); // Superficie elevada (cards, inputs)
  static const Color gray = Color(0xFF7A8C82); // Gris verdoso apagado
  static const Color gray50 = Color(
    0x407A8C82,
  ); // Gris al 25% para bordes sutiles
  static const Color error = Color(
    0xFFB5543A,
  ); // Rojo-tierra (no choca con el verde)
}

class AppTheme {
  static ThemeData dark() {
    const colorScheme = ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: AppColors.accent,
      secondary: AppColors.accent,
      onSecondary: AppColors.background,
      surface: AppColors.surface,
      onSurface: AppColors.accent,
      error: AppColors.error,
      onError: AppColors.accent,
    );

    final baseTextTheme = Typography.material2021().white.apply(
      bodyColor: AppColors.accent,
      displayColor: AppColors.accent,
      fontFamily: 'Trebuchet MS',
      fontFamilyFallback: const ['Helvetica'],
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Trebuchet MS',
      textTheme: baseTextTheme.copyWith(
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: AppColors.gray),
        labelMedium: baseTextTheme.labelMedium?.copyWith(color: AppColors.gray),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.accent,
        elevation: 0,
        centerTitle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        labelStyle: const TextStyle(color: AppColors.gray),
        prefixIconColor: AppColors.gray,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.gray50),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.gray50),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        errorStyle: const TextStyle(color: AppColors.error),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.accent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Trebuchet MS',
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: const BorderSide(color: AppColors.gray50, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontFamily: 'Trebuchet MS',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.accent,
      ),
    );
  }
}
