
import 'package:flutter/material.dart';

import 'redesign_colors.dart';

abstract final class AppTheme {
  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: RedesignColors.purple,
      brightness: Brightness.dark,
      surface: RedesignColors.card,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,

      // Identidade visual principal
      scaffoldBackgroundColor: RedesignColors.background,
      cardColor: RedesignColors.card,

      // Tipografia global
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: RedesignColors.textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: RedesignColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: RedesignColors.textSecondary,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: RedesignColors.textSecondary,
          fontSize: 14,
        ),
      ),

      // Barra superior
      appBarTheme: const AppBarTheme(
        backgroundColor: RedesignColors.background,
        foregroundColor: RedesignColors.textPrimary,
        centerTitle: false,
        elevation: 0,
      ),

      // Cards
      cardTheme: CardThemeData(
        color: RedesignColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: RedesignColors.border,
          ),
        ),
      ),

      // Campos de entrada
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: RedesignColors.card,
        hintStyle: const TextStyle(
          color: RedesignColors.textSecondary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: RedesignColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: RedesignColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: RedesignColors.purple,
            width: 1.5,
          ),
        ),
      ),

      // Botões principais
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: RedesignColors.purple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Divisores
      dividerTheme: const DividerThemeData(
        color: RedesignColors.border,
        thickness: 1,
      ),
    );
  }

  // Tema claro mantido para compatibilidade futura.
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF3157D5),
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF6F7FB),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
    );
  }
}
