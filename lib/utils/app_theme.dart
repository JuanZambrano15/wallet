// lib/utils/app_theme.dart

import 'package:flutter/material.dart';

class AppColors {
  // ── Paleta base ──────────────────────────────────────────────
  static const Color primary    = Color(0xFF004F39); // Verde bosque
  static const Color accent     = Color(0xFFFFFACA); // Crema
  static const Color background = Color(0xFF151613); // Fondo
  static const Color surface    = Color(0xFF1F2220); // Cards / inputs
  static const Color surface2   = Color(0xFF252722); // Modales
  static const Color surface3   = Color(0xFF2C2F28); // Inputs dentro de modales
  static const Color gray       = Color(0xFF7A8C82); // Gris verdoso
  static const Color gray50     = Color(0x407A8C82); // Bordes sutiles
  static const Color error      = Color(0xFFB5543A); // Rojo-tierra

  // ── Semánticos / acentos ─────────────────────────────────────
  static const Color tealAccent  = Color(0xFF7EEBB8); // Ingresos / positivo
  static const Color redAccent   = Color(0xFFFF8A8A); // Gastos / negativo
  static const Color amberAccent = Color(0xFFFAC775); // Advertencias / freelance

  // ── Bordes ────────────────────────────────────────────────────
  static const Color border  = Color(0x14FFFACA); // 8% cream — borde sutil
  static const Color border2 = Color(0x24FFFACA); // 14% cream — borde énfasis

  // ── Texto ─────────────────────────────────────────────────────
  static const Color accentDim   = Color(0x8DFFFACA); // 55% cream
  static const Color accentMuted = Color(0x40FFFACA); // 25% cream
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
        fillColor: AppColors.surface3,
        labelStyle: const TextStyle(color: AppColors.gray),
        prefixIconColor: AppColors.gray,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        errorStyle: const TextStyle(color: AppColors.error),
        counterStyle: const TextStyle(color: AppColors.accentMuted, fontSize: 10),
        hintStyle: const TextStyle(color: AppColors.accentMuted, fontSize: 13),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.accent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontFamily: 'Trebuchet MS',
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: const BorderSide(color: AppColors.border2, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.tealAccent,
          textStyle: const TextStyle(
            fontFamily: 'Trebuchet MS',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.background,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surface2,
        contentTextStyle: const TextStyle(color: AppColors.accent, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}