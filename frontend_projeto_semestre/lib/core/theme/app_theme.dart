import 'package:flutter/material.dart';
import 'automatize_palette.dart';

abstract final class AppTheme {
  // Navegação direta, sem slide ou zoom.
  static final PageTransitionsTheme _pageTransitionsTheme =
      PageTransitionsTheme(
        builders: {
          for (final platform in TargetPlatform.values)
            platform: const _SemTransicaoPageTransitionsBuilder(),
        },
      );

  // Tema escuro da aplicação.
  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AutomatizePalette.primary,
      brightness: Brightness.dark,
      surface: AutomatizePalette.panel,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AutomatizePalette.background,
      cardColor: AutomatizePalette.panel,

      // Configuração da navegação.
      pageTransitionsTheme: _pageTransitionsTheme,

      appBarTheme: const AppBarTheme(
        backgroundColor: AutomatizePalette.panel,
        foregroundColor: AutomatizePalette.text,
        centerTitle: false,
        elevation: 0,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AutomatizePalette.panel,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Tema claro da aplicação.
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AutomatizePalette.primary,
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

class _SemTransicaoPageTransitionsBuilder extends PageTransitionsBuilder {
  const _SemTransicaoPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}
