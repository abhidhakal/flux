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
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(_buildSnackbar(
        context: context,
        message: message,
        type: type,
        duration: duration,
        onAction: onAction,
        actionLabel: actionLabel,
        icon: icon,
      ));
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
    final cs = theme.colorScheme;
    final accentColor = _accentColor(type, cs);
    final defaultIcon = _defaultIcon(type);

    return SnackBar(
      duration: duration,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      padding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outline.withOpacity(0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left accent bar
                Container(width: 4, color: accentColor),
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    child: Row(
                      children: [
                        Icon(icon ?? defaultIcon, color: accentColor, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            message,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ),
                        if (onAction != null && actionLabel != null) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: onAction,
                            child: Text(
                              actionLabel,
                              style: TextStyle(
                                color: accentColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Color _accentColor(AppSnackbarType type, ColorScheme cs) {
    switch (type) {
      case AppSnackbarType.success:
        return AppColors.success;
      case AppSnackbarType.error:
        return AppColors.error;
      case AppSnackbarType.warning:
        return AppColors.warning;
      case AppSnackbarType.info:
        return cs.primary;
    }
  }

  static IconData _defaultIcon(AppSnackbarType type) {
    switch (type) {
      case AppSnackbarType.success:
        return Icons.check_circle_rounded;
      case AppSnackbarType.error:
        return Icons.error_rounded;
      case AppSnackbarType.warning:
        return Icons.warning_rounded;
      case AppSnackbarType.info:
        return Icons.info_rounded;
    }
  }

  // Convenience methods
  static void showSuccess(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) =>
      show(context, message: message, type: AppSnackbarType.success,
          duration: duration, onAction: onAction, actionLabel: actionLabel);

  static void showError(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onAction,
    String? actionLabel,
  }) =>
      show(context, message: message, type: AppSnackbarType.error,
          duration: duration, onAction: onAction, actionLabel: actionLabel);

  static void showWarning(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) =>
      show(context, message: message, type: AppSnackbarType.warning,
          duration: duration, onAction: onAction, actionLabel: actionLabel);

  static void showInfo(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) =>
      show(context, message: message, type: AppSnackbarType.info,
          duration: duration, onAction: onAction, actionLabel: actionLabel);
}
