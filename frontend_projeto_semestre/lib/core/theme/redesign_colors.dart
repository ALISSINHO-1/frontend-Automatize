import 'package:flutter/material.dart';

abstract final class RedesignColors {
  // Fundos
  static const background = Color(0xFF0C1020);
  static const sidebar = Color(0xFF10162B);
  static const card = Color(0xFF171D32);

  // Cores de destaque
  static const purple = Color(0xFF7667F5);
  static const cyan = Color(0xFF35C8F5);
  static const amber = Color(0xFFF2AE60);
  static const green = Color(0xFF34D5AE);

  // Textos e bordas
  static const textPrimary = Color(0xFFE7E9FF);
  static const textSecondary = Color(0xFFA7AEC8);
  static const border = Color(0xFF303956);

  // Degradê discreto para o fundo
  static const backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF111A38),
      Color(0xFF0C1020),
      Color(0xFF15102C),
    ],
  );
}