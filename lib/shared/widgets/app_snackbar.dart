import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
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
      content: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.backgroundColor,
              borderRadius: BorderRadius.circular(AppTheme.radius8),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon ?? defaultIcon,
              color: colors.iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getTitleForType(type),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.normal,
                    color: colorScheme.onSurface.withOpacity(0.7),
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ],
            ),
          ),
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(width: AppTheme.spacing8),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: colors.actionColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing12,
                  vertical: AppTheme.spacing8,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ),
          ],
        ],
      ),
      backgroundColor: colorScheme.surface,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(AppTheme.spacing16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius12),
        side: BorderSide(
          color: colors.borderColor,
          width: 1,
        ),
      ),
      elevation: 4,
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

  static String _getTitleForType(AppSnackbarType type) {
    switch (type) {
      case AppSnackbarType.success:
        return 'Success';
      case AppSnackbarType.error:
        return 'Error';
      case AppSnackbarType.warning:
        return 'Warning';
      case AppSnackbarType.info:
        return 'Info';
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
