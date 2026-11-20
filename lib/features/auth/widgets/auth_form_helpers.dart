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

/// Shared layout for login/signup: back button, brand mark, heading, form,
/// and a footer link to the other auth screen.
class AuthScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final String footerText;
  final String footerAction;
  final VoidCallback onFooterTap;

  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.footerText,
    required this.footerAction,
    required this.onFooterTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (Navigator.canPop(context))
                    IconButton.filledTonal(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor:
                            cs.surfaceContainerHighest.withValues(alpha: 0.6),
                        foregroundColor: cs.onSurface,
                      ),
                    ),
                  const Spacer(),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.asset('assets/images/flux_logo.png',
                        width: 30, height: 30),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              Text(
                title,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              child,
              const SizedBox(height: 28),
              Center(
                child: TextButton(
                  onPressed: onFooterTap,
                  child: Text.rich(
                    TextSpan(
                      text: '$footerText  ',
                      style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w500),
                      children: [
                        TextSpan(
                          text: footerAction,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "or" divider between the email form and Google.
Widget authOrDivider(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 22),
    child: Row(
      children: [
        Expanded(child: Divider(color: cs.outline.withValues(alpha: 0.2))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('or',
              style: TextStyle(
                  color: cs.onSurfaceVariant, fontWeight: FontWeight.w500)),
        ),
        Expanded(child: Divider(color: cs.outline.withValues(alpha: 0.2))),
      ],
    ),
  );
}

ButtonStyle authPrimaryButtonStyle() => ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
      minimumSize: const Size.fromHeight(56),
      shape: const StadiumBorder(),
      elevation: 0,
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
    );

ButtonStyle authGoogleButtonStyle(BuildContext context) =>
    OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(56),
      shape: const StadiumBorder(),
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    );
