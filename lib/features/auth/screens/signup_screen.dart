import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../auth_bloc.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../core/constants/app_theme.dart';

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
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets;
    final isKeyboardOpen = viewInsets.bottom > 0;
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: AppColors.primary,
      resizeToAvoidBottomInset: true,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthLoading) {
            setState(() => _isLoading = true);
            _showLoadingDialog();
          } else {
            if (_isLoading) {
              setState(() => _isLoading = false);
              Navigator.of(context, rootNavigator: true).pop();
            }
          }

          if (state is AuthError) {
            AppSnackbar.showError(context, message: state.message);
          }

          if (state is AuthAuthenticated) {
            AppSnackbar.showSuccess(context, message: 'Account created successfully!');
          }
        },
        child: Column(
          children: [
            // Top Part - Doodle & Back Button (Animated height)
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.fastOutSlowIn,
              height: isKeyboardOpen ? 120 : size.height * 0.3,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                image: DecorationImage(
                  image: AssetImage('assets/images/flux_doodle.png'),
                  fit: BoxFit.cover,
                  opacity: 0.3,
                ),
              ),
              child: SafeArea(
                child: Stack(
                  children: [
                    if (!isKeyboardOpen)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Join Flux',
                            style: (isKeyboardOpen 
                              ? theme.textTheme.headlineSmall 
                              : theme.textTheme.displaySmall)?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!isKeyboardOpen) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Start your journey with us',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Name Field
                          TextFormField(
                            controller: _nameController,
                            decoration: _buildInputDecoration(
                              label: 'Full Name',
                              hint: 'Enter your full name',
                              icon: Icons.person_outlined,
                              theme: theme,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: isKeyboardOpen ? 12 : 12),
 
                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _buildInputDecoration(
                              label: 'Email',
                              hint: 'Enter your email',
                              icon: Icons.email_outlined,
                              theme: theme,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: isKeyboardOpen ? 12 : 12),
 
                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            decoration: _buildInputDecoration(
                              label: 'Password',
                              hint: 'Enter your password',
                              icon: Icons.lock_outlined,
                              isPassword: true,
                              isVisible: _isPasswordVisible,
                              onToggleVisibility: () {
                                setState(() => _isPasswordVisible = !_isPasswordVisible);
                              },
                              theme: theme,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: isKeyboardOpen ? 12 : 12),
 
                          // Confirm Password Field
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: !_isConfirmPasswordVisible,
                            decoration: _buildInputDecoration(
                              label: 'Confirm Password',
                              hint: 'Confirm your password',
                              icon: Icons.lock_outlined,
                              isPassword: true,
                              isVisible: _isConfirmPasswordVisible,
                              onToggleVisibility: () {
                                setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
                              },
                              theme: theme,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          
                          SizedBox(height: isKeyboardOpen ? 16 : 24),
 
                          // Sign Up Button
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleSignUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Create Account',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 16),
 
                          // Divider
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'OR',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 16),

                          OutlinedButton.icon(
                            onPressed: _isLoading ? null : _handleGoogleSignIn,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const FaIcon(
                              FontAwesomeIcons.google,
                              color: Color(0xFFDB4437),
                              size: 20,
                            ),
                            label: Text(
                              'Continue with Google',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
 
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: RichText(
                              text: TextSpan(
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                                children: const [
                                  TextSpan(text: 'Already have an account? '),
                                  TextSpan(
                                    text: 'Sign In',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onToggleVisibility,
    required ThemeData theme,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.primary),
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(
                isVisible ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: onToggleVisibility,
            )
          : null,
    );
  }

  void _showLoadingDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                height: 40,
                width: 40,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Creating Account...',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
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

  void _handleGoogleSignIn() {
    context.read<AuthBloc>().add(GoogleSignInRequested());
  }
}

