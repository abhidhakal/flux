import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/constants/app_theme.dart';
import 'package:flutter/services.dart';
import 'core/services/auth_service.dart';
import 'core/services/budget_service.dart';
import 'core/services/transaction_service.dart';
import 'core/services/ai_intelligence_service.dart';
import 'core/services/goal_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/enhanced_notification_service.dart';
import 'core/services/currency_service.dart';
import 'core/services/network_service.dart';
import 'core/services/subscription_service.dart';
import 'features/subscription/subscription_bloc.dart';
import 'features/auth/auth_bloc.dart';
import 'core/constants/app_colors.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/budget/budget_bloc.dart';
import 'features/transaction/transaction_bloc.dart';
import 'features/analytics/analytics_bloc.dart';
import 'features/goals/goals_bloc.dart';
import 'features/notifications/notifications_bloc.dart';
import 'features/theme/theme_bloc.dart';
import 'shared/widgets/loading_screen.dart';
import 'features/main/screens/main_screen.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final EnhancedNotificationService _notificationService = EnhancedNotificationService();

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await _notificationService.initialize();
      await CurrencyService().initialize();
      await NetworkService().initialize();
      // SubscriptionService is initialized in the Bloc, but we can also do it here if needed
      // or just let the Bloc handle it on creation/event.
    } catch (e) {
      print('Failed to initialize services: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeBloc>(
          create: (context) => ThemeBloc()..add(ThemeLoadRequested()),
        ),
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(
            authService: AuthService(),
          )..add(AuthCheckRequested()),
        ),
        BlocProvider<BudgetBloc>(
          create: (context) => BudgetBloc(
            budgetService: BudgetService(),
          ),
        ),
        BlocProvider<TransactionBloc>(
          create: (context) => TransactionBloc(
            transactionService: TransactionService(),
          ),
        ),
        BlocProvider<AnalyticsBloc>(
          create: (context) => AnalyticsBloc(
            aiService: AIIntelligenceService(),
          ),
        ),
        BlocProvider<GoalsBloc>(
          create: (context) => GoalsBloc(
            goalService: GoalService(),
          ),
        ),
        BlocProvider<NotificationsBloc>(
          create: (context) => NotificationsBloc(
            notificationService: NotificationService(),
          ),
        ),
        BlocProvider<SubscriptionBloc>(
          create: (context) => SubscriptionBloc(
            subscriptionService: SubscriptionService(),
          )..add(SubscriptionCheckRequested()),
        ),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          ThemeMode themeMode = ThemeMode.light;
          if (themeState is ThemeLoaded) {
            themeMode = themeState.themeMode;
          }

          return MaterialApp(
            title: 'Flux',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              final Widget safeContent = SafeArea(
                top: true,
                bottom: true,
                left: false,
                right: false,
                child: child ?? const SizedBox.shrink(),
              );
              final theme = Theme.of(context);
              final isDark = theme.brightness == Brightness.dark;
              final overlay = isDark
                  ? const SystemUiOverlayStyle(
                      statusBarColor: Colors.transparent,
                      statusBarIconBrightness: Brightness.light,
                      statusBarBrightness: Brightness.dark,
                      systemNavigationBarColor: Colors.transparent,
                      systemNavigationBarIconBrightness: Brightness.light,
                      systemNavigationBarDividerColor: Colors.transparent,
                    )
                  : const SystemUiOverlayStyle(
                      statusBarColor: AppColors.primary,
                      statusBarIconBrightness: Brightness.light,
                      statusBarBrightness: Brightness.light,
                      systemNavigationBarColor: AppColors.lightBackground,
                      systemNavigationBarIconBrightness: Brightness.light,
                      systemNavigationBarDividerColor: AppColors.lightBackground,
                    );
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: overlay,
                child: safeContent,
              );
            },
            home: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is AuthLoading) {
                  return const LoadingScreen();
                } else if (state is AuthAuthenticated) {
                  return const MainScreen();
                } else {
                  return const LoginScreen();
                }
              },
            ),
          );
        },
      ),
    );
  }
}
