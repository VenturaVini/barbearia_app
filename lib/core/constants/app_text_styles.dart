import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Estilos de texto da aplicação
class AppTextStyles {
  AppTextStyles._();

  // Base Text Style
  static TextStyle get _baseStyle => GoogleFonts.montserrat(
        color: AppColors.textPrimary,
      );

  static TextStyle get _basePoppins => GoogleFonts.poppins(
        color: AppColors.textPrimary,
      );

  // Display (Títulos muito grandes)
  static TextStyle get displayLarge => _baseStyle.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      );

  static TextStyle get displayMedium => _baseStyle.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.bold,
      );

  static TextStyle get displaySmall => _baseStyle.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
      );

  // Headlines (Títulos de seções)
  static TextStyle get headlineLarge => _baseStyle.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get headlineMedium => _baseStyle.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get headlineSmall => _baseStyle.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      );

  // Titles (Títulos de cards e componentes)
  static TextStyle get titleLarge => _basePoppins.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get titleMedium => _basePoppins.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get titleSmall => _basePoppins.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      );

  // Body (Texto de corpo)
  static TextStyle get bodyLarge => _basePoppins.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get bodyMedium => _basePoppins.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get bodySmall => _basePoppins.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      );

  // Labels (Botões, badges, labels)
  static TextStyle get labelLarge => _baseStyle.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      );

  static TextStyle get labelMedium => _baseStyle.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      );

  static TextStyle get labelSmall => _baseStyle.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      );

  // Estilos Especiais
  static TextStyle get goldAccent => _baseStyle.copyWith(
        color: AppColors.gold,
        fontWeight: FontWeight.bold,
      );

  static TextStyle get price => _baseStyle.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.gold,
      );

  static TextStyle get caption => _basePoppins.copyWith(
        fontSize: 12,
        color: AppColors.textMuted,
      );

  static TextStyle get overline => _baseStyle.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.5,
        color: AppColors.textMuted,
      );

  // Estilos de Botão
  static TextStyle get buttonLarge => _baseStyle.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      );

  static TextStyle get buttonMedium => _baseStyle.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      );

  static TextStyle get buttonSmall => _baseStyle.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      );

  // Estilos de erro/sucesso
  static TextStyle get error => bodyMedium.copyWith(
        color: AppColors.error,
      );

  static TextStyle get success => bodyMedium.copyWith(
        color: AppColors.success,
      );

  static TextStyle get warning => bodyMedium.copyWith(
        color: AppColors.warning,
      );
}
