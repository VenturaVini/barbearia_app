import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// Utilitários para SnackBars
class SnackBarUtils {
  SnackBarUtils._();

  /// Mostrar snackbar de sucesso
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: AppColors.success,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surface,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.success, width: 1),
        ),
      ),
    );
  }

  /// Mostrar snackbar de erro
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error,
              color: AppColors.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surface,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.error, width: 1),
        ),
      ),
    );
  }

  /// Mostrar snackbar de aviso
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.warning,
              color: AppColors.warning,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surface,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.warning, width: 1),
        ),
      ),
    );
  }

  /// Mostrar snackbar de informação
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.info,
              color: AppColors.info,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surface,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.info, width: 1),
        ),
      ),
    );
  }

  /// Mostrar snackbar customizado
  static void show(
    BuildContext context,
    String message, {
    IconData? icon,
    Color? iconColor,
    Color? borderColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: iconColor ?? AppColors.textPrimary,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surface,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: borderColor ?? AppColors.border,
            width: 1,
          ),
        ),
      ),
    );
  }
}
