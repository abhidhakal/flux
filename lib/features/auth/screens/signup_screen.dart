import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../auth_bloc.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/google_logo.dart';
import '../../../shared/widgets/app_form_fields.dart';
import '../widgets/auth_form_helpers.dart';
import 'login_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
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
          showAuthLoadingDialog(context, 'Creating account…');
        } else if (_isLoading) {
          setState(() => _isLoading = false);
          Navigator.of(context, rootNavigator: true).pop();
        }
        if (state is AuthError) {
          AppSnackbar.showError(context, message: state.message);
        }
        if (state is AuthAuthenticated) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: AuthScaffold(
        title: 'Create your account',
        subtitle: 'Takes less than a minute. Free to start.',
        footerText: 'Already have an account?',
        footerAction: 'Sign in',
        onFooterTap: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              authLabel(context, 'Name'),
              const SizedBox(height: 8),
              AppTextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                hintText: 'What should we call you?',
                prefixIcon: const Icon(LucideIcons.user),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter your name'
                    : null,
              ),
              const SizedBox(height: 18),
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
              authLabel(context, 'Password'),
              const SizedBox(height: 8),
              AppTextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                onFieldSubmitted: (_) => _handleSignUp(),
                hintText: 'At least 6 characters',
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
                onPressed: _isLoading ? null : _handleSignUp,
                style: authPrimaryButtonStyle(),
                child: const Text('Create account'),
              ),
              authOrDivider(context),
              OutlinedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () => context.read<AuthBloc>().add(GoogleSignInRequested()),
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

  void _handleSignUp() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            SignUpRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              displayName: _nameController.text.trim(),
            ),
          );
    }
  }
}
