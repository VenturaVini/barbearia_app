import 'package:flutter/material.dart';

/// Paleta de cores da Barbearia (baseado no projeto original)
class AppColors {
  AppColors._();

  // Cores Principais
  static const Color primaryDark = Color(0xFF1C1C1C); // Background principal
  static const Color surface = Color(0xFF2E2E2E); // Cards e superfícies
  static const Color muted = Color(0xFF4A4A4A); // Bordas e divisores

  // Cores de Destaque
  static const Color gold = Color(0xFFD4AF37); // Dourado premium (botões, destaques)
  static const Color wood = Color(0xFF8B5E3C); // Marrom madeira (secundário)

  // Textos
  static const Color textPrimary = Color(0xFFFFFFFF); // Texto principal
  static const Color textMuted = Color(0xFFCCCCCC); // Texto secundário
  static const Color border = Color(0xFF3A3A3A); // Bordas

  // Status
  static const Color success = Color(0xFF00AA00); // Confirmado
  static const Color error = Color(0xFFFF4444); // Cancelado
  static const Color warning = Color(0xFFFFA500); // Pendente
  static const Color info = Color(0xFF4A90E2); // Informação

  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [gold, Color(0xFFB8941F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [primaryDark, Color(0xFF0A0A0A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Cores de Overlay
  static const Color overlay = Color(0x80000000); // Overlay escuro 50%
  static const Color overlayLight = Color(0x40000000); // Overlay escuro 25%

  // Cores de Status Badge
  static const Color pending = warning;
  static const Color confirmed = info;
  static const Color completed = success;
  static const Color cancelled = error;

  // Shimmer Colors
  static const Color shimmerBase = muted;
  static const Color shimmerHighlight = surface;
}
