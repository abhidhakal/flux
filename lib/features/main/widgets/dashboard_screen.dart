import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flux/features/main/widgets/budgets_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/services/currency_service.dart';
import '../../../core/services/profile_picture_service.dart';
import '../../../shared/widgets/skeleton_components.dart';

import '../../../core/models/transaction_model.dart';
import '../../auth/auth_bloc.dart';
import '../../analytics/analytics_bloc.dart';
import '../../transaction/transaction_bloc.dart';
import '../../budget/budget_bloc.dart';
import '../../goals/screens/goals_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../notifications/notifications_bloc.dart';
import '../../transaction/screens/add_transaction_screen.dart';
import '../../income/income_bloc.dart';
import '../../../core/models/income_model.dart';

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
    // Load data when screen initializes
    final user = context.read<AuthBloc>().state;
    if (user is AuthAuthenticated) {
      context.read<TransactionBloc>().add(LoadTransactions(user.user.id));
      context.read<BudgetBloc>().add(LoadBudgets(user.user.id));
      context.read<NotificationsBloc>().add(LoadNotifications(user.user.id));
      context.read<IncomeBloc>().add(LoadIncome(user.user.id));
    }
    _profilePictureService.loadProfileImage();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: false,
        backgroundColor: colorScheme.background,
        foregroundColor: colorScheme.onBackground,
        iconTheme: IconThemeData(color: colorScheme.onBackground),
        titleTextStyle: TextStyle(
          color: colorScheme.onBackground,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        actions: [
          // Goals button
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
          // Notifications button with badge
          BlocBuilder<NotificationsBloc, NotificationsState>(
            builder: (context, state) {
              int unreadCount = 0;
              if (state is NotificationsLoaded) {
                unreadCount =
                    state.notifications.where((n) => n.isUnread).length;
              }

              return Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications_none_rounded,
                        color: Theme.of(context).colorScheme.onBackground),
                    tooltip: 'Notifications',
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
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
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
        ],
      ),
      body: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (context, transactionState) {
          if (transactionState is TransactionLoading) {
            return _buildDashboardSkeleton();
          }

          if (transactionState is TransactionLoaded) {
            // Trigger analytics when transactions are loaded
            context.read<AnalyticsBloc>().add(
                  AnalyzeSpendingPatterns(transactionState.transactions),
                );

            return BlocBuilder<IncomeBloc, IncomeState>(
              builder: (context, incomeState) {
                // Determine if we should show loading
                // If transactions are loaded but income is still loading, maybe just show stats with 0 income or wait?
                // Let's assume Loaded for simplicity or check both.
                
                final incomeList = (incomeState is IncomeLoaded) ? incomeState.incomes : <Income>[];

                return BlocBuilder<AnalyticsBloc, AnalyticsState>(
                  builder: (context, analyticsState) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing12,
                        vertical: AppTheme.spacing16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWelcomeSection(),
                          const SizedBox(height: AppTheme.spacing16),
                          _buildQuickActionButtons(),
                          const SizedBox(height: AppTheme.spacing24),
                          _buildQuickStats(transactionState.transactions, incomeList),
                          const SizedBox(height: AppTheme.spacing24),
                          _buildAIInsights(analyticsState),
                          const SizedBox(height: AppTheme.spacing24),
                          _buildRecentTransactions(transactionState.transactions),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          }

          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.dashboard,
                  size: 64,
                  color: AppColors.primary,
                ),
                SizedBox(height: 16),
                Text(
                  'Welcome to Flux Dashboard!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Your financial overview will appear here.',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;

          // Reload profile picture when this widget builds
          _profilePictureService.loadProfileImage();

          return Card(
            elevation: 0,
            color: colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius20),
              side: BorderSide(
                color: colorScheme.outline,
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacing20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacing8),
                        decoration: BoxDecoration(
                          color: colorScheme.outline.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radius12),
                        ),
                        child: _profilePictureService.buildProfileAvatar(
                          displayName: state.user.displayName,
                          colorScheme: colorScheme,
                          radius: 20,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacing16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back,',
                              style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.7),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              state.user.displayName ?? 'User',
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacing8),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radius12),
                      border: Border.all(
                        color: colorScheme.outline,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spacing8),
                          decoration: BoxDecoration(
                            color: colorScheme.outline.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radius8),
                          ),
                          child: Icon(
                            Icons.trending_up_rounded,
                            color: colorScheme.onSurface,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacing12),
                        Expanded(
                          child: Text(
                            'Here\'s your financial overview',
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildQuickActionButtons() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            title: 'Add Transaction',
            subtitle: 'Record income or expense',
            icon: Icons.add_circle_outline_rounded,
            color: Colors.green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddTransactionScreen(),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: AppTheme.spacing12),
        Expanded(
          child: _buildActionButton(
            title: 'Manage Budget',
            subtitle: 'Set spending limits',
            icon: Icons.account_balance_wallet_outlined,
            color: AppColors.secondary,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BudgetsScreen(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      color: color.withOpacity(0.9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radius16),
        child: Container(
          height: 100, // Fixed height for consistent button sizes
          padding: const EdgeInsets.all(AppTheme.spacing16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radius16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.95),
                color.withOpacity(0.85),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacing8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radius8),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.8),
                      letterSpacing: 0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(List<dynamic> transactions, List<Income> incomes) {
    final expenses =
        transactions.where((t) => t.type == TransactionType.expense).toList();
    // Income is now separate list

    final totalExpenses = expenses.fold(0.0, (sum, t) => sum + t.amount);
    final totalIncome = incomes.fold(0.0, (sum, i) => sum + i.amount);
    final balance = totalIncome - totalExpenses;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Income',
                CurrencyService().formatAmount(totalIncome),
                Icons.trending_up_rounded,
                AppColors.success,
              ),
            ),
            const SizedBox(width: AppTheme.spacing8),
            Expanded(
              child: _buildStatCard(
                'Expenses',
                CurrencyService().formatAmount(totalExpenses),
                Icons.trending_down_rounded,
                AppColors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing8),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Balance',
                CurrencyService().formatAmount(balance),
                Icons.account_balance_rounded,
                balance >= 0 ? AppColors.primary : AppColors.error,
              ),
            ),
            const SizedBox(width: AppTheme.spacing8),
            Expanded(
              child: _buildStatCard(
                'Transactions',
                '${transactions.length}',
                Icons.payments_rounded,
                AppColors.secondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: color.withOpacity(0.05), // Subtle colored background matching icon
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius16),
        side: BorderSide(
          color: color.withOpacity(0.2), // Subtle colored border matching icon
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radius12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppTheme.spacing4),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIInsights(AnalyticsState analyticsState) {
    if (analyticsState is AnalyticsLoading) {
      return SkeletonComponents.card(
        height: 200,
        children: [
          Row(
            children: [
              SkeletonComponents.circle(size: 32, context: context),
              const SizedBox(width: 12),
              SkeletonComponents.textLine(width: 100, height: 18),
            ],
          ),
          const SizedBox(height: 16),
          SkeletonComponents.textLine(width: double.infinity, height: 16),
          const SizedBox(height: 8),
          SkeletonComponents.textLine(width: 200, height: 14),
          const SizedBox(height: 12),
          SkeletonComponents.textLine(width: double.infinity, height: 16),
          const SizedBox(height: 8),
          SkeletonComponents.textLine(width: 150, height: 14),
        ], context: context,
      );
    }

    if (analyticsState is SpendingAnalysisLoaded) {
      final analysis = analyticsState.analysis;
      final insights = analysis['insights'] as List<dynamic>;
      final recommendations = analysis['recommendations'] as List<dynamic>;

      return Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius20),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacing8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radius8),
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing12),
                  Text(
                    'AI Insights',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (insights.isNotEmpty) ...[
                Text(
                  'Key Insights:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                ...insights.map((insight) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.lightbulb_outline,
                              size: 16,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              insight as String,
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.7)),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 16),
              ],
              if (recommendations.isNotEmpty) ...[
                Text(
                  'Recommendations:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                ...recommendations.map((rec) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.tips_and_updates,
                              size: 16,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              rec as String,
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.7)),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildRecentTransactions(List<dynamic> transactions) {
    final recentTransactions = transactions.take(5).toList();

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius20),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacing8),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.outline.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radius8),
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    color: Theme.of(context).colorScheme.secondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Text(
                  'Recent Transactions',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing16),
            if (recentTransactions.isEmpty)
              Center(
                child: Text(
                  'No transactions yet',
                  style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7)),
                ),
              )
            else
              ...recentTransactions.map((transaction) => Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: transaction.type == TransactionType.expense
                                ? AppColors.error.withValues(alpha: 0.1)
                                : AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            transaction.type == TransactionType.expense
                                ? Icons.remove_circle_outline_outlined
                                : Icons.add_circle_outline_rounded,
                            color: transaction.type == TransactionType.expense
                                ? AppColors.error
                                : AppColors.success,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacing12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                transaction.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                transaction.category,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          CurrencyService().formatAmount(transaction.amount),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: transaction.type == TransactionType.expense
                                ? AppColors.error
                                : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  // Update the skeleton to include action buttons
  Widget _buildDashboardSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing12,
        vertical: AppTheme.spacing16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome section skeleton
          SkeletonComponents.card(
            height: 120,
            children: [
              Row(
                children: [
                  SkeletonComponents.circle(size: 40, context: context),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonComponents.textLine(width: 100, height: 14),
                        const SizedBox(height: 4),
                        SkeletonComponents.textLine(width: 120, height: 18),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SkeletonComponents.textLine(width: double.infinity, height: 40),
            ], context: context,
          ),
          const SizedBox(height: AppTheme.spacing16),
          
          // Quick action buttons skeleton
          Row(
            children: [
              Expanded(child: SkeletonComponents.card(height: 120, context: context)),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(child: SkeletonComponents.card(height: 120, context: context)),
            ],
          ),
          const SizedBox(height: AppTheme.spacing24),
          
          // Quick stats skeleton
          Column(
            children: [
              Row(
                children: [
                  Expanded(child: SkeletonComponents.dashboardStat(context: context)),
                  const SizedBox(width: AppTheme.spacing8),
                  Expanded(child: SkeletonComponents.dashboardStat(context: context)),
                ],
              ),
              const SizedBox(height: AppTheme.spacing8),
              Row(
                children: [
                  Expanded(child: SkeletonComponents.dashboardStat(context: context)),
                  const SizedBox(width: AppTheme.spacing8),
                  Expanded(child: SkeletonComponents.dashboardStat(context: context)),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing24),
          
          // AI Insights skeleton
          SkeletonComponents.card(
            height: 200,
            children: [
              Row(
                children: [
                  SkeletonComponents.circle(size: 32, context: context),
                  const SizedBox(width: 12),
                  SkeletonComponents.textLine(width: 100, height: 18),
                ],
              ),
              const SizedBox(height: 16),
              SkeletonComponents.textLine(width: double.infinity, height: 16),
              const SizedBox(height: 8),
              SkeletonComponents.textLine(width: 200, height: 14),
              const SizedBox(height: 12),
              SkeletonComponents.textLine(width: double.infinity, height: 16),
              const SizedBox(height: 8),
              SkeletonComponents.textLine(width: 150, height: 14),
            ], context: context,
          ),
          const SizedBox(height: AppTheme.spacing24),
          
          // Recent transactions skeleton
          SkeletonComponents.card(
            height: 300,
            children: [
              Row(
                children: [
                  SkeletonComponents.circle(size: 32, context: context),
                  const SizedBox(width: 12),
                  SkeletonComponents.textLine(width: 150, height: 18),
                ],
              ),
              const SizedBox(height: 16),
              ...List.generate(5, (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SkeletonComponents.transactionListItem(context: context),
              )),
            ], context: context,
          ),
        ],
      ),
    );
  }
}
