import 'package:flutter/material.dart';

abstract final class AppTheme {
  // Transição suave entre as telas, sem efeito de zoom.
  static final PageTransitionsTheme _pageTransitionsTheme =
      PageTransitionsTheme(
        builders: {
          for (final platform in TargetPlatform.values)
            platform: const FadeUpwardsPageTransitionsBuilder(),
        },
      );

  // Tema escuro da aplicação.
  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF637BFF),
      brightness: Brightness.dark,
      surface: const Color(0xFF171B26),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0F131C),
      cardColor: const Color(0xFF181C24),

      // Configuração da navegação.
      pageTransitionsTheme: _pageTransitionsTheme,

      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF181C24),
        foregroundColor: Color(0xFFDFE2EE),
        centerTitle: false,
        elevation: 0,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF181C24),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Tema claro da aplicação.
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF3157D5),
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF6F7FB),

      // Mantém a mesma transição utilizada no tema escuro.
      pageTransitionsTheme: _pageTransitionsTheme,

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
