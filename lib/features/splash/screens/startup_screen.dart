import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_theme.dart';
import '../../auth/auth_bloc.dart';
import '../../auth/screens/welcome_screen.dart';
import '../../main/screens/main_screen.dart';

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  static const _minimumSplashDuration = Duration(milliseconds: 1600);

  late final Timer _minimumTimer;

  bool _minimumTimeElapsed = false;

  @override
  void initState() {
    super.initState();
    _minimumTimer = Timer(_minimumSplashDuration, () {
      if (!mounted) return;
      setState(() {
        _minimumTimeElapsed = true;
      });
    });
  }

  @override
  void dispose() {
    _minimumTimer.cancel();
    super.dispose();
  }

  bool _isAuthResolved(AuthState state) {
    return state is! AuthInitial && state is! AuthLoading;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final readyToProceed = _minimumTimeElapsed && _isAuthResolved(authState);

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: readyToProceed
              ? _buildDestination(authState)
              : const _SplashPresentation(key: ValueKey('startup-splash')),
        );
      },
    );
  }

  Widget _buildDestination(AuthState authState) {
    if (authState is AuthAuthenticated) {
      return const MainScreen(key: ValueKey('main-screen'));
    }

    return const WelcomeScreen(key: ValueKey('welcome-screen'));
  }
}

class _SplashPresentation extends StatefulWidget {
  const _SplashPresentation({super.key});

  @override
  State<_SplashPresentation> createState() => _SplashPresentationState();
}

class _SplashPresentationState extends State<_SplashPresentation>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _loaderController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<Offset> _textOffset;
  late final Animation<double> _textFade;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
    _loaderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    _logoScale = Tween<double>(begin: 0.82, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutBack,
      ),
    );
    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0, 0.55, curve: Curves.easeOut),
      ),
    );
    _textOffset = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.25, 0.9, curve: Curves.easeOutCubic),
      ),
    );
    _textFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _loaderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  isDark ? const Color(0xFF111827) : const Color(0xFFF6FBFF),
                  isDark ? AppColors.darkBackground : AppColors.lightBackground,
                ],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: Container(
                      width: 112,
                      height: 112,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Image.asset('assets/images/flux_logo.png'),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                FadeTransition(
                  opacity: _textFade,
                  child: SlideTransition(
                    position: _textOffset,
                    child: Column(
                      children: [
                        Text(
                          'Flux',
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.2,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Clarity for every dollar.',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha: 0.68),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                AnimatedBuilder(
                  animation: _loaderController,
                  builder: (context, child) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (index) {
                        final distance = (_loaderController.value - (index * 0.18)).abs();
                        final normalized = (1 - (distance * 2.2)).clamp(0.0, 1.0);
                        final scale = 0.82 + (normalized * 0.34);
                        final opacity = 0.24 + (normalized * 0.76);

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          child: Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary.withValues(alpha: opacity),
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
