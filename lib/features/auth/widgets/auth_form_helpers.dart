import 'package:flutter/material.dart';
import '../../../core/constants/app_theme.dart';

/// Shared field validation for the login/signup forms, so the rules can't
/// drift between the two screens.
class AuthValidators {
  static bool isValidEmail(String email) => email.contains('@');

  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your email';
    if (!isValidEmail(value)) return 'Please enter a valid email';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your password';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }
}

/// Section label used above each auth form field.
Widget authLabel(BuildContext context, String text) {
  final theme = Theme.of(context);
  return Text(
    text,
    style: theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurface,
    ),
  );
}

/// Shared text-field decoration for the login/signup forms.
InputDecoration authInputDecoration(
  BuildContext context, {
  required String hint,
  required IconData icon,
  Widget? suffix,
}) {
  final cs = Theme.of(context).colorScheme;
  return InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
    suffixIcon: suffix,
    filled: true,
    fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.35),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.15))),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cs.error)),
    focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cs.error, width: 1.5)),
  );
}

/// Shared blocking loading dialog shown while an auth request is in flight.
void showAuthLoadingDialog(BuildContext context, String message) {
  final theme = Theme.of(context);
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 40,
              width: 40,
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 3),
            ),
            const SizedBox(height: 16),
            Text(message,
                style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none)),
          ],
        ),
      ),
    ),
  );
}
