import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/google_logo.dart';
import '../auth_bloc.dart';
import '../widgets/flux_preview.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    // This screen gets unmounted the instant AuthLoading fires (StartupScreen
    // swaps to its own splash loader for that state), so if we're remounted
    // after a failed sign-in the error already happened before this State
    // existed — a BlocListener only catches *future* transitions, not the
    // state that's already current. Surface it once on mount too.
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) AppSnackbar.showError(context, message: authState.message);
      });
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _interval(double a, double b) => CurvedAnimation(
        parent: _controller,
        curve: Interval(a, b, curve: Curves.easeOutCubic),
      );

  Widget _reveal(double start, Widget child) {
    final a = _interval(start, start + 0.4);
    return FadeTransition(
      opacity: a,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.25), end: Offset.zero)
            .animate(a),
        child: child,
      ),
    );
  }

  void _push(Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    const bg = AppColors.tertiaryDark;
    final muted = Colors.white.withValues(alpha: 0.64);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: bg,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: bg,
        body: BlocListener<AuthBloc, AuthState>(
          // AuthLoading needs no handling here — StartupScreen already swaps
          // to its own full-screen splash for that state.
          listener: (context, state) {
            if (state is AuthError) {
              AppSnackbar.showError(context, message: state.message);
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Soft brand glow behind the preview cards.
              const Positioned(
                top: -120,
                left: -80,
                right: -80,
                height: 520,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [Color(0x550079DC), Color(0x000079DC)],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, c) => SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: c.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Spacer(),
                            const SizedBox(height: 32),
                            FluxPreview(t: _interval(0.1, 1)),
                            const SizedBox(height: 40),
                            const Spacer(),
                            _reveal(
                              0.3,
                              Align(
                                alignment: Alignment.centerLeft,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    'assets/images/flux_logo.png',
                                    width: 44,
                                    height: 44,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _reveal(
                              0.35,
                              const Text(
                                'Know where\nevery dollar goes.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  height: 1.08,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _reveal(
                              0.42,
                              Text(
                                'Track spending, set budgets that hold, and watch your goals get closer.',
                                style: TextStyle(
                                  color: muted,
                                  fontSize: 16,
                                  height: 1.45,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            _reveal(
                              0.5,
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _PillButton(
                                    onPressed: () => context
                                        .read<AuthBloc>()
                                        .add(GoogleSignInRequested()),
                                    background: Colors.white,
                                    foreground: AppColors.tertiaryDark,
                                    icon: const GoogleLogo(size: 20),
                                    label: 'Continue with Google',
                                  ),
                                  const SizedBox(height: 12),
                                  _PillButton(
                                    onPressed: () =>
                                        _push(const LoginScreen()),
                                    background:
                                        Colors.white.withValues(alpha: 0.08),
                                    foreground: Colors.white,
                                    border:
                                        Colors.white.withValues(alpha: 0.14),
                                    label: 'Sign in with email',
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () =>
                                        _push(const SignUpScreen()),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                    ),
                                    child: Text.rich(
                                      TextSpan(
                                        text: 'New to Flux?  ',
                                        style: TextStyle(
                                            color: muted,
                                            fontWeight: FontWeight.w500),
                                        children: const [
                                          TextSpan(
                                            text: 'Create an account',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
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

class _PillButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Color background;
  final Color foreground;
  final Color? border;
  final Widget? icon;
  final String label;

  const _PillButton({
    required this.onPressed,
    required this.background,
    required this.foreground,
    required this.label,
    this.border,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: StadiumBorder(
        side: border == null ? BorderSide.none : BorderSide(color: border!),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[icon!, const SizedBox(width: 10)],
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
