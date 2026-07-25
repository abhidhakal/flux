import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flux/features/main/widgets/budgets_screen.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/services/currency_service.dart';
import '../../../core/services/profile_picture_service.dart';
import '../../../core/services/stale_budget_helper.dart';
import '../../../core/services/widget_service.dart';
import '../../../shared/widgets/skeleton_components.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../core/widgets/app_banner_ad.dart';

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
import '../navigation_cubit.dart';
import 'package:lucide_icons/lucide_icons.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ProfilePictureService _profilePictureService = ProfilePictureService();
  static const _balanceVisiblePrefKey = 'dashboard_balance_visible';
  bool _isBalanceVisible = true;

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
    _loadBalanceVisibility();
  }

  Future<void> _loadBalanceVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _isBalanceVisible = prefs.getBool(_balanceVisiblePrefKey) ?? true;
    });
  }

  Future<void> _toggleBalanceVisibility() async {
    setState(() => _isBalanceVisible = !_isBalanceVisible);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_balanceVisiblePrefKey, _isBalanceVisible);
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
                            border: Border.all(
                                color: colorScheme.outline.withOpacity(0.08)),
                          ),
                          child: ListenableBuilder(
                            listenable: _profilePictureService,
                            builder: (context, _) =>
                                _profilePictureService.buildProfileAvatar(
                              displayName: state.user.displayName,
                              colorScheme: colorScheme,
                              radius: 20, // Slightly bigger
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: AppTheme.sectionSubtitleStyle(context)
                                  .copyWith(fontSize: 12),
                            ),
                            Text(
                              state.user.displayName?.split(' ').first ??
                                  'User',
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
              icon: Icon(LucideIcons.flag, color: colorScheme.onBackground),
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
                final unreadCount =
                    state is NotificationsLoaded ? state.unreadCount : 0;

                return Stack(
                  children: [
                    IconButton(
                      icon: Icon(LucideIcons.bell,
                          color: colorScheme.onBackground),
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
              final transactions = transactionState.transactions;
              final isEmpty = transactions.isEmpty;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(
                    left: 16, right: 16, top: 24, bottom: 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBalanceCard(transactions),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    if (isEmpty)
                      _buildFirstRunNudge()
                    else ...[
                      _buildSmartInsights(),
                      const SizedBox(height: 24),
                      _buildRecentTransactions(transactions),
                      const SizedBox(height: 24),
                      _buildFinancialTips(),
                      const SizedBox(height: 16),
                    ],
                    const AppBannerAd(),
                    const SizedBox(height: 32),
                  ],
                ),
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  /// This month's net vs last month's net, as a % change. Null when last
  /// month has no activity to compare against (percent change would be
  /// meaningless off a zero base).
  ({bool isUp, double percent})? _computeMonthlyTrend(
      List<Transaction> transactions) {
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    double netFor(DateTime start, DateTime end) {
      return transactions
          .where((t) => !t.date.isBefore(start) && t.date.isBefore(end))
          .fold<double>(
              0, (sum, t) => sum + (t.isIncome ? t.amount : -t.amount));
    }

    final thisMonthNet = netFor(thisMonthStart, tomorrow);
    final lastMonthNet = netFor(lastMonthStart, thisMonthStart);
    if (lastMonthNet == 0) return null;

    final percent = ((thisMonthNet - lastMonthNet) / lastMonthNet.abs()) * 100;
    return (isUp: percent >= 0, percent: percent.abs());
  }

  Widget _buildBalanceCard(List<Transaction> transactions) {
    final totalExpenses = transactions.totalExpenses();
    final totalIncome = transactions.totalIncome();
    final balance = transactions.netBalance;
    final trend = _computeMonthlyTrend(transactions);

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Total Balance',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: _toggleBalanceVisibility,
                          child: Icon(
                            _isBalanceVisible
                                ? LucideIcons.eye
                                : LucideIcons.eyeOff,
                            size: 15,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isBalanceVisible
                          ? CurrencyService().formatAmount(balance)
                          : '••••••',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (trend != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (trend.isUp ? AppColors.success : AppColors.error)
                        .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trend.isUp
                            ? LucideIcons.trendingUp
                            : LucideIcons.trendingDown,
                        size: 13,
                        color: trend.isUp ? AppColors.success : AppColors.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${trend.percent.toStringAsFixed(1)}% vs last month',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color:
                              trend.isUp ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
            decoration: BoxDecoration(
              color: colorScheme.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outline.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildBalanceStat(
                    'Income',
                    CurrencyService().formatAmount(totalIncome),
                    LucideIcons.arrowUp,
                    AppColors.success,
                    colorScheme,
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: colorScheme.outline.withOpacity(0.12),
                ),
                Expanded(
                  child: _buildBalanceStat(
                    'Expense',
                    CurrencyService().formatAmount(totalExpenses),
                    LucideIcons.arrowDown,
                    AppColors.error,
                    colorScheme,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceStat(String label, String value, IconData icon,
      Color color, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 12),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
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
            LucideIcons.plus,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AddTransactionScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionButton(
            'Budget',
            LucideIcons.wallet,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BudgetsScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Dark mode: near-black surface + white text (kept, already looked
    // right). Light mode: the same white/near-white card surface used
    // everywhere else in the app, not a solid color block — no shadow glow.
    final fg = isDark ? Colors.white : AppColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppTheme.cardSurface(context),
          borderRadius: BorderRadius.circular(20),
          border: isDark
              ? null
              : Border.all(color: theme.colorScheme.outline.withOpacity(0.08)),
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

  Widget _buildSmartInsights() {
    return BlocBuilder<AnalyticsBloc, AnalyticsState>(
      builder: (context, state) {
        if (state is SpendingAnalysisLoaded) {
          final insights = state.analysis['insights'] as List? ?? [];
          if (insights.isEmpty) return const SizedBox.shrink();

          final colorScheme = Theme.of(context).colorScheme;
          final topInsights = insights.take(2).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withOpacity(0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.sparkles,
                        size: 14, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Smart Insights',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onBackground,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: AppTheme.tintedSurfaceDecoration(
                  context,
                  tint: colorScheme.primary,
                  radius: 20,
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < topInsights.length; i++) ...[
                      if (i > 0)
                        Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: colorScheme.primary.withOpacity(0.10),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Text(
                          topInsights[i].toString(),
                          style: TextStyle(
                            height: 1.4,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildFirstRunNudge() {
    return EmptyStateView(
      icon: LucideIcons.scrollText,
      iconColor: Theme.of(context).colorScheme.primary,
      title: 'No transactions yet',
      titleFontSize: 16,
      subtitle: 'Add your first transaction to see it here.',
      actionLabel: 'Add Transaction',
      actionIcon: LucideIcons.plus,
      onAction: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
        );
      },
    );
  }

  Widget _buildRecentTransactions(List<Transaction> transactions) {
    if (transactions.isEmpty) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;
    final recent = transactions.take(4).toList();

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
                color: colorScheme.onBackground,
              ),
            ),
            TextButton(
              onPressed: () => context.read<NavigationCubit>().setTab(2),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration:
              AppTheme.surfaceDecoration(context, radius: 18, subtle: true),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            children: [
              for (var i = 0; i < recent.length; i++) ...[
                if (i > 0)
                  Divider(
                      height: 1, color: colorScheme.outline.withOpacity(0.08)),
                _CompactTransactionRow(
                  item: recent[i],
                  onTap: () => context.read<NavigationCubit>().setTab(2),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialTips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.lightbulb, color: AppColors.secondaryDark, size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Tip: tracking small daily expenses can save up to 20% more each month.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: AppColors.secondaryDark,
              ),
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
              Expanded(
                  child: SkeletonComponents.card(height: 60, context: context)),
              const SizedBox(width: 16),
              Expanded(
                  child: SkeletonComponents.card(height: 60, context: context)),
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

/// Dense single-line row for the dashboard's "recent" preview — the full
/// TransactionTile (44px icon, bordered card, 16/14 padding) is built for
/// browsing the full transaction list, not a quick glance.
class _CompactTransactionRow extends StatelessWidget {
  final Transaction item;
  final VoidCallback onTap;

  const _CompactTransactionRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isIncome = item.isIncome;
    final accentColor = isIncome ? AppColors.success : AppColors.error;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                isIncome ? LucideIcons.plus : LucideIcons.minus,
                color: accentColor,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${isIncome ? '+' : '-'}${CurrencyService().formatAmount(item.amount)}',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: accentColor,
              ),
            ),
          ],
        ),
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
