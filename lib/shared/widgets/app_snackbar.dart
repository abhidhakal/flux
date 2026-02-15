import 'package:flutter/material.dart';
import '../../core/constants/app_theme.dart';

enum AppSnackbarType {
  success,
  error,
  warning,
  info,
}

class AppSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    AppSnackbarType type = AppSnackbarType.info,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
    IconData? icon,
  }) {
    final snackBar = _buildSnackbar(
      context: context,
      message: message,
      type: type,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
      icon: icon,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static SnackBar _buildSnackbar({
    required BuildContext context,
    required String message,
    required AppSnackbarType type,
    required Duration duration,
    VoidCallback? onAction,
    String? actionLabel,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final colors = _getColorsForType(type, colorScheme);
    final defaultIcon = _getDefaultIconForType(type);

    return SnackBar(
      content: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ?? defaultIcon,
              color: colors.iconColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onInverseSurface,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  foregroundColor: colors.actionColor,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      backgroundColor: colorScheme.inverseSurface,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      elevation: 0,
    );
  }

  static _SnackbarColors _getColorsForType(AppSnackbarType type, ColorScheme colorScheme) {
    switch (type) {
      case AppSnackbarType.success:
        return _SnackbarColors(
          backgroundColor: AppColors.success.withOpacity(0.1),
          iconColor: AppColors.success,
          borderColor: AppColors.success.withOpacity(0.3),
          actionColor: AppColors.success,
        );
      case AppSnackbarType.error:
        return _SnackbarColors(
          backgroundColor: AppColors.error.withOpacity(0.1),
          iconColor: AppColors.error,
          borderColor: AppColors.error.withOpacity(0.3),
          actionColor: AppColors.error,
        );
      case AppSnackbarType.warning:
        return _SnackbarColors(
          backgroundColor: AppColors.warning.withOpacity(0.1),
          iconColor: AppColors.warning,
          borderColor: AppColors.warning.withOpacity(0.3),
          actionColor: AppColors.warning,
        );
      case AppSnackbarType.info:
        return _SnackbarColors(
          backgroundColor: colorScheme.primary.withOpacity(0.1),
          iconColor: colorScheme.primary,
          borderColor: colorScheme.primary.withOpacity(0.3),
          actionColor: colorScheme.primary,
        );
    }
  }

  static IconData _getDefaultIconForType(AppSnackbarType type) {
    switch (type) {
      case AppSnackbarType.success:
        return Icons.check_circle;
      case AppSnackbarType.error:
        return Icons.error;
      case AppSnackbarType.warning:
        return Icons.warning;
      case AppSnackbarType.info:
        return Icons.info;
    }
  }

  // Convenience methods for common use cases
  static void showSuccess(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    show(
      context,
      message: message,
      type: AppSnackbarType.success,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  static void showError(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    show(
      context,
      message: message,
      type: AppSnackbarType.error,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  static void showWarning(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    show(
      context,
      message: message,
      type: AppSnackbarType.warning,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  static void showInfo(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    show(
      context,
      message: message,
      type: AppSnackbarType.info,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }
}

class _SnackbarColors {
  final Color backgroundColor;
  final Color iconColor;
  final Color borderColor;
  final Color actionColor;

  const _SnackbarColors({
    required this.backgroundColor,
    required this.iconColor,
    required this.borderColor,
    required this.actionColor,
  });
}
