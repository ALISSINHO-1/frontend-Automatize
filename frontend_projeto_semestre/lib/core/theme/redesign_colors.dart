import 'package:flutter/material.dart';
import 'automatize_palette.dart';

/// Compatibilidade com as telas técnicas, usando uma paleta única.
abstract final class RedesignColors {
  static const background = AutomatizePalette.background;
  static const sidebar = AutomatizePalette.sidebar;
  static const card = AutomatizePalette.panel;
  static const primary = AutomatizePalette.primary;
  static const purple = AutomatizePalette.purple;
  static const cyan = AutomatizePalette.cyan;
  static const amber = AutomatizePalette.warning;
  static const green = AutomatizePalette.success;
  static const textPrimary = AutomatizePalette.text;
  static const textSecondary = AutomatizePalette.muted;
  static const border = AutomatizePalette.border;

  static const backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AutomatizePalette.panel, AutomatizePalette.background, AutomatizePalette.sidebar],
  );
}
