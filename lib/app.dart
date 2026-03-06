import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_widget/home_widget.dart';
import 'core/constants/app_theme.dart';
import 'package:flutter/services.dart';
import 'core/services/auth_service.dart';
import 'core/services/budget_service.dart';
import 'core/services/transaction_service.dart';
import 'core/services/ai_intelligence_service.dart';
import 'core/services/goal_service.dart';
import 'core/services/enhanced_notification_service.dart';
import 'core/services/notification_trigger_service.dart';
import 'core/services/currency_service.dart';
import 'core/services/network_service.dart';
import 'core/services/subscription_service.dart';
import 'core/services/background_task_service.dart';
import 'features/subscription/subscription_bloc.dart';
import 'features/auth/auth_bloc.dart';
import 'features/auth/screens/welcome_screen.dart';
import 'features/budget/budget_bloc.dart';
import 'features/transaction/transaction_bloc.dart';
import 'features/analytics/analytics_bloc.dart';
import 'features/goals/goals_bloc.dart';
import 'features/notifications/notifications_bloc.dart';
import 'features/main/navigation_cubit.dart';
import 'features/theme/theme_bloc.dart';
import 'features/main/screens/main_screen.dart';
import 'core/services/income_service.dart';
import 'features/income/income_bloc.dart';
import 'features/transaction/screens/add_transaction_screen.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final EnhancedNotificationService _notificationService = EnhancedNotificationService();
  final NotificationTriggerService _triggerService = NotificationTriggerService();
  final AuthService _authService = AuthService();
  final BudgetService _budgetService = BudgetService();
  final TransactionService _transactionService = TransactionService();
  final IncomeService _incomeService = IncomeService();
  final AIIntelligenceService _aiService = AIIntelligenceService();
  final GoalService _goalService = GoalService();
  final SubscriptionService _subscriptionService = SubscriptionService();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<NavigationCubit>(
          create: (context) => NavigationCubit(),
        ),
        BlocProvider<ThemeBloc>(
          create: (context) => ThemeBloc()..add(ThemeLoadRequested()),
        ),
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(
            authService: _authService,
          )..add(AuthCheckRequested()),
        ),
        BlocProvider<BudgetBloc>(
          create: (context) => BudgetBloc(
            budgetService: _budgetService,
            notificationTriggerService: _triggerService,
          ),
        ),
        BlocProvider<TransactionBloc>(
          create: (context) => TransactionBloc(
            transactionService: _transactionService,
            budgetService: _budgetService,
            notificationTriggerService: _triggerService,
            enhancedNotificationService: _notificationService,
          ),
        ),
        BlocProvider<IncomeBloc>(
          create: (context) => IncomeBloc(
            incomeService: _incomeService,
          ),
        ),
        BlocProvider<AnalyticsBloc>(
          create: (context) => AnalyticsBloc(
            aiService: _aiService,
          ),
        ),
        BlocProvider<GoalsBloc>(
          create: (context) => GoalsBloc(
            goalService: _goalService,
            notificationTriggerService: _triggerService,
          ),
        ),
        BlocProvider<NotificationsBloc>(
          create: (context) => NotificationsBloc(
            notificationService: _notificationService,
          ),
        ),
        BlocProvider<SubscriptionBloc>(
          create: (context) => SubscriptionBloc(
            subscriptionService: _subscriptionService,
          )..add(SubscriptionCheckRequested()),
        ),
      ],
      child: AppView(notificationService: _notificationService),
    );
  }
}

class AppView extends StatefulWidget {
  final EnhancedNotificationService notificationService;
  const AppView({super.key, required this.notificationService});

  @override
  State<AppView> createState() => _AppViewState();
}

class _AppViewState extends State<AppView> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  Uri? _pendingUri;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _setupHomeWidget();
  }

  Future<void> _initializeServices() async {
    try {
      // Initialize critical services in parallel
      await Future.wait([
        CurrencyService().initialize(),
        NetworkService().initialize(),
      ]);

      // Defer non-critical/heavy services like Notifications until after first frame
      // to improve perceived startup performance.
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          await widget.notificationService.initialize();
        } catch (e) {
          debugPrint('Background notification initialization failed: $e');
        }
      });
    } catch (e) {
      debugPrint('Failed to initialize critical services: $e');
    }
  }

  void _setupHomeWidget() {
    HomeWidget.setAppGroupId('group.com.klivostudios.flux');
    HomeWidget.initiallyLaunchedFromHomeWidget().then(_handleWidgetLaunch);
    HomeWidget.widgetClicked.listen(_handleWidgetLaunch);
  }

  void _handleWidgetLaunch(Uri? uri) {
    if (uri == null) return;
    _pendingUri = uri;
    _checkPendingWidgetLaunch();
  }

  void _checkPendingWidgetLaunch() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && _pendingUri != null) {
      final uri = _pendingUri!;
      _pendingUri = null;
      
      // Use a slight delay to ensure the MainScreen is fully mounted and ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (uri.host == 'add_transaction') {
            _navigatorKey.currentState?.push(
              MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
            );
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              context.read<SubscriptionBloc>().add(SubscriptionCheckRequested());
              _checkPendingWidgetLaunch();
              
              // Register background health checks for notifications
              BackgroundTaskService().registerDailyHealthCheck(state.user.id);
            }
          },
        ),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          ThemeMode themeMode = ThemeMode.system;
          if (themeState is ThemeLoaded) {
            themeMode = themeState.themeMode;
          }

          return MaterialApp(
            navigatorKey: _navigatorKey,
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
                if (state is AuthAuthenticated) {
                  return const MainScreen();
                }

                if (state is AuthLoading || state is AuthInitial) {
                  return const WelcomeScreen();
                }

                return const WelcomeScreen();
              },
            ),
          );
        },
      ),
    );
  }
}


