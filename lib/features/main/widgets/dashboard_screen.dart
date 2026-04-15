import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flux/features/main/widgets/budgets_screen.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/services/currency_service.dart';
import '../../../core/services/profile_picture_service.dart';
import '../../../core/services/stale_budget_helper.dart';
import '../../../core/services/widget_service.dart';
import '../../../shared/widgets/skeleton_components.dart';
import '../../../core/widgets/app_banner_ad.dart';
import '../../../core/services/feature_flag_service.dart';

import '../../../core/models/transaction_model.dart';
import '../../auth/auth_bloc.dart';
import '../../analytics/analytics_bloc.dart';
import '../../transaction/transaction_bloc.dart';
import '../../budget/budget_bloc.dart';
import '../../goals/goals_bloc.dart';
import '../../goals/screens/goals_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../notifications/notifications_bloc.dart';
import '../../transaction/screens/add_transaction_screen.dart';
import '../../subscription/subscription_bloc.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ProfilePictureService _profilePictureService = ProfilePictureService();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthBloc>().state;
    if (user is AuthAuthenticated) {
      _profilePictureService.loadProfileImage(userId: user.user.id).then((_) {
        if (mounted) setState(() {});
      });
    } else {
       // Should wait for auth or handle unauthenticated state if needed
       // But usually Dashboard is protected. 
    }
  }

  void _updateWidget(BuildContext context) {
    WidgetService.refreshWidgets(context);
  }

  void _checkStaleBudgets() {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final budgetState = context.read<BudgetBloc>().state;
    final txState = context.read<TransactionBloc>().state;

    if (budgetState is BudgetLoaded && txState is TransactionLoaded) {
      StaleBudgetHelper.checkAndShowAlert(
        context,
        budgets: budgetState.budgets,
        transactions: txState.transactions,
        userId: authState.user.id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MultiBlocListener(
      listeners: [
        BlocListener<TransactionBloc, TransactionState>(
          listener: (context, state) {
            if (state is TransactionLoaded) {
              _updateWidget(context);
              _checkStaleBudgets();
              context.read<AnalyticsBloc>().add(
                    AnalyzeSpendingPatterns(state.transactions),
                  );
            }
          },
        ),
        BlocListener<BudgetBloc, BudgetState>(
          listener: (context, state) {
            if (state is BudgetLoaded) {
              _checkStaleBudgets();
            }
          },
        ),
        BlocListener<GoalsBloc, GoalsState>(
          listener: (context, state) {
            if (state is GoalsLoaded) {
              _updateWidget(context);
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: AppTheme.pageBackground(context),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Row(
            children: [
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is AuthAuthenticated) {
                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.cardSurface(context),
                          border: Border.all(color: colorScheme.outline.withOpacity(0.08)),
                        ),
                        child: _profilePictureService.buildProfileAvatar(
                          displayName: state.user.displayName,
                          colorScheme: colorScheme,
                          radius: 20, // Slightly bigger
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getGreeting(),
                            style: AppTheme.sectionSubtitleStyle(context).copyWith(fontSize: 12),
                          ),
                          Text(
                            state.user.displayName?.split(' ').first ?? 'User',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        centerTitle: false,
        backgroundColor: AppTheme.pageBackground(context),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.outlined_flag_rounded, color: colorScheme.onBackground),
            tooltip: 'Goals',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GoalsScreen(),
                ),
              );
            },
          ),
          BlocBuilder<NotificationsBloc, NotificationsState>(
            builder: (context, state) {
              int unreadCount = 0;
              if (state is NotificationsLoaded) {
                unreadCount = state.notifications.where((n) => n.status.name == 'unread').length;
              }
              
              return Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications_outlined, color: colorScheme.onBackground),
                    onPressed: () {
                       Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (context, transactionState) {
          if (transactionState is TransactionLoading) {
            return _buildDashboardSkeleton();
          }

          if (transactionState is TransactionLoaded) {
            return BlocBuilder<SubscriptionBloc, SubscriptionState>(
              builder: (context, subscriptionState) {
                final hasPremiumAccess =
                    !FeatureFlagService.isSubscriptionEnabled ||
                    subscriptionState is SubscriptionPremium;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBalanceCard(transactionState.transactions),
                      const SizedBox(height: 24),
                      _buildQuickActions(),
                      const SizedBox(height: 24),
                      _buildSmartInsights(hasPremiumAccess),
                      const SizedBox(height: 24),
                      _buildRecentTransactions(transactionState.transactions),
                      const SizedBox(height: 32),
                      _buildFinancialTips(),
                      const SizedBox(height: 16),
                      const AppBannerAd(),
                      const SizedBox(height: 32),
                    ],
                  ),
                );
              },
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    ),
  );
}

  Widget _buildBalanceCard(List<Transaction> transactions) {
    final expenses = transactions.where((t) => t.isExpense).toList();
    final incomes = transactions.where((t) => t.isIncome).toList();
    final totalExpenses = expenses.fold(0.0, (sum, t) => sum + t.amount);
    final totalIncome = incomes.fold(0.0, (sum, t) => sum + t.amount);
    final balance = totalIncome - totalExpenses;
    
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Total Balance',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyService().formatAmount(balance),
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 36,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildBalanceStat(
                  'Income',
                  CurrencyService().formatAmount(totalIncome),
                  Icons.arrow_upward_rounded,
                  const Color(0xFF22C55E),
                  colorScheme,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: colorScheme.outline.withOpacity(0.1),
              ),
              Expanded(
                child: _buildBalanceStat(
                  'Expense',
                  CurrencyService().formatAmount(totalExpenses),
                  Icons.arrow_downward_rounded,
                  const Color(0xFFEF4444),
                  colorScheme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceStat(String label, String value, IconData icon, Color color, ColorScheme colorScheme) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 12),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            'Add New',
            Icons.add_rounded,
            const Color(0xFF2b2b2b),
            Colors.white,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionButton(
            'Budget',
            Icons.pie_chart_outline_rounded,
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.onSurface,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BudgetsScreen()),
              );
            },
            isOutlined: true,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color bg, Color fg, VoidCallback onTap, {bool isOutlined = false}) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 60,
        decoration: isOutlined
            ? AppTheme.surfaceDecoration(context, radius: 20, subtle: true).copyWith(
                border: Border.all(color: fg.withOpacity(0.08)),
              )
            : BoxDecoration(
                color: theme.brightness == Brightness.dark ? const Color(0xFF161616) : Colors.black,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.20 : 0.14),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: fg, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartInsights(bool isPremium) {
    if (!isPremium) {
      return Stack(
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: _buildDummyInsights(),
          ),
          Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.lock_rounded, color: Colors.white, size: 14),
                        SizedBox(width: 8),
                        Text(
                          'Premium Feature',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ),
        ],
      );
    }
    
    return BlocBuilder<AnalyticsBloc, AnalyticsState>(
      builder: (context, state) {
        if (state is SpendingAnalysisLoaded) {
           final insights = state.analysis['insights'] as List? ?? [];
           if (insights.isEmpty) return const SizedBox.shrink();

           return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 20, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Smart Insights',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.surfaceDecoration(context),
                  child: Column(
                    children: insights.take(2).map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Padding(
                             padding: const EdgeInsets.only(top: 2),
                             child: Icon(Icons.check_circle_outline_rounded, size: 16, color: Theme.of(context).colorScheme.primary),
                           ),
                           const SizedBox(width: 12),
                           Expanded(child: Text(e.toString(), style: const TextStyle(height: 1.4))),
                        ],
                      ),
                    )).toList(),
                  ),
                ),
              ],
           );
        }
        return const SizedBox.shrink();
      },
    );
  }
  
  Widget _buildDummyInsights() {
     return Opacity(
       opacity: 0.5,
       child: Column(
         mainAxisSize: MainAxisSize.min,
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 20, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Smart Insights',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
           Container(
             height: 120,
             width: double.infinity,
             decoration: AppTheme.surfaceDecoration(context),
             padding: const EdgeInsets.all(20),
             child: Column(
               children: [
                 Row(children: [Container(width: 200, height: 12, color: Colors.grey)]),
                 SizedBox(height: 10),
                 Row(children: [Container(width: 150, height: 12, color: Colors.grey)]),
               ],
             ),
           ),
         ],
       ),
     );
  }

  Widget _buildRecentTransactions(List<Transaction> transactions) {
    if (transactions.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to transactions tab
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          children: List.generate(
            transactions.length > 4 ? 4 : transactions.length,
            (index) {
              final t = transactions[index];
              final isExpense = t.type == TransactionType.expense;
              final isLast = index == ((transactions.length > 4 ? 4 : transactions.length) - 1);

              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.mutedSurface(context)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(
                        Theme.of(context).brightness == Brightness.dark ? 0.14 : 0.08,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isExpense ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          isExpense ? Icons.shopping_bag_outlined : Icons.attach_money_rounded,
                          color: isExpense ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.title,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              t.category,
                              style: AppTheme.sectionSubtitleStyle(context).copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${isExpense ? "-" : "+"}${CurrencyService().formatAmount(t.amount)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isExpense ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialTips() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_rounded, color: AppColors.secondaryDark, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Did you know?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Tracking small daily expenses can help you save up to 20% more each month. Keep it up!',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.secondaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SkeletonComponents.card(height: 180, context: context),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: SkeletonComponents.card(height: 60, context: context)),
              const SizedBox(width: 16),
              Expanded(child: SkeletonComponents.card(height: 60, context: context)),
            ],
          ),
          const SizedBox(height: 24),
          SkeletonComponents.card(height: 120, context: context),
          const SizedBox(height: 24),
          SkeletonComponents.card(height: 300, context: context),
        ],
      ),
    );
  }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning,';
    } else if (hour < 17) {
      return 'Good Afternoon,';
    } else {
      return 'Good Evening,';
    }
  }
