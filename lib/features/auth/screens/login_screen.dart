import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../auth_bloc.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/google_logo.dart';
import '../../../shared/widgets/app_form_fields.dart';
import '../../../core/constants/app_theme.dart';
import '../widgets/auth_form_helpers.dart';
import 'signup_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLoading) {
          setState(() => _isLoading = true);
          showAuthLoadingDialog(context, 'Signing in…');
        } else {
          if (_isLoading) {
            setState(() => _isLoading = false);
            Navigator.of(context, rootNavigator: true).pop();
          }
          if (state is AuthAuthenticated) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        }
        if (state is AuthError) {
          AppSnackbar.showError(context, message: state.message);
        }
        if (state is AuthSuccess) {
          AppSnackbar.showSuccess(context, message: state.message);
        }
      },
      child: AuthScaffold(
        title: 'Welcome back',
        subtitle: 'Sign in to pick up where you left off.',
        footerText: "Don't have an account?",
        footerAction: 'Create one',
        onFooterTap: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SignUpScreen()),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              authLabel(context, 'Email'),
              const SizedBox(height: 8),
              AppTextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                hintText: 'name@example.com',
                prefixIcon: const Icon(LucideIcons.mail),
                validator: AuthValidators.email,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  authLabel(context, 'Password'),
                  const Spacer(),
                  GestureDetector(
                    onTap: _handleForgotPassword,
                    child: const Text(
                      'Forgot?',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AppTextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => _handleLogin(),
                hintText: 'Your password',
                prefixIcon: const Icon(LucideIcons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? LucideIcons.eyeOff : LucideIcons.eye,
                    size: 20,
                    color: cs.onSurfaceVariant,
                  ),
                  onPressed: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
                validator: AuthValidators.password,
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: authPrimaryButtonStyle(),
                child: const Text('Sign in'),
              ),
              authOrDivider(context),
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _handleGoogleSignIn,
                style: authGoogleButtonStyle(context),
                icon: const GoogleLogo(size: 20),
                label: const Text('Continue with Google'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(SignInRequested(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ));
    }
  }

  void _handleGoogleSignIn() =>
      context.read<AuthBloc>().add(GoogleSignInRequested());

  void _handleForgotPassword() {
    final theme = Theme.of(context);
    final authBloc = context.read<AuthBloc>();
    final ctrl = TextEditingController(text: _emailController.text);

    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Reset password',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Enter your email and we'll send a reset link.",
                style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            AppTextField(
              controller: ctrl,
              keyboardType: TextInputType.emailAddress,
              hintText: 'name@example.com',
              prefixIcon: const Icon(LucideIcons.mail),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: Text('Cancel',
                style: TextStyle(
                    color: Theme.of(dCtx).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              final email = ctrl.text.trim();
              if (email.isNotEmpty && AuthValidators.isValidEmail(email)) {
                authBloc.add(PasswordResetRequested(email: email));
                Navigator.pop(dCtx);
              } else {
                AppSnackbar.showError(context,
                    message: 'Please enter a valid email');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: const StadiumBorder(),
              elevation: 0,
            ),
            child: const Text('Send link',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
