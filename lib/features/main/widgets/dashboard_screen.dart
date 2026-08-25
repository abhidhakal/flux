import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/services/currency_service.dart';
import '../../../core/services/profile_picture_service.dart';
import '../../../core/services/stale_budget_helper.dart';
import '../../../core/services/widget_service.dart';
import '../../../core/services/onboarding_service.dart';
import '../../../shared/widgets/skeleton_components.dart';
import '../../../shared/widgets/empty_state_view.dart';

import '../../../core/models/transaction_model.dart';
import '../../../core/models/recurring_transaction_model.dart';
import '../../../core/services/recurring_transaction_service.dart';
import '../../../core/utils/date_format_utils.dart';
import '../../auth/auth_bloc.dart';
import '../../analytics/analytics_bloc.dart';
import '../../transaction/transaction_bloc.dart';
import '../../budget/budget_bloc.dart';
import '../../budget/screens/add_budget_screen.dart';
import '../../goals/goals_bloc.dart';
import '../../goals/screens/goals_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../notifications/notifications_bloc.dart';
import '../../transaction/screens/add_transaction_screen.dart';
import '../../transaction/screens/recurring_transactions_screen.dart';
import '../navigation_cubit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _dashboardBlue = AppColors.primary;
  final ProfilePictureService _profilePictureService = ProfilePictureService();
  final RecurringTransactionService _recurringTransactionService =
      RecurringTransactionService();
  static const _balanceVisiblePrefKey = 'dashboard_balance_visible';
  bool _isBalanceVisible = true;
  bool _onboardingComplete = false;
  Future<List<RecurringTransaction>>? _recurringTransactionsFuture;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthBloc>().state;
    if (user is AuthAuthenticated) {
      _loadOnboardingState(user.user.id);
      _recurringTransactionsFuture = _recurringTransactionService
          .getUserRecurringTransactions(user.user.id);
      _profilePictureService.loadProfileImage(userId: user.user.id).then((_) {
        if (mounted) setState(() {});
      });
    } else {
      // Should wait for auth or handle unauthenticated state if needed
      // But usually Dashboard is protected.
    }
    _loadBalanceVisibility();
  }

  Future<void> _loadOnboardingState(String userId) async {
    final complete = await OnboardingService().isComplete(userId);
    if (!mounted) return;
    setState(() => _onboardingComplete = complete);
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
    final colorScheme = Theme.of(context).colorScheme;

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
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: AppTheme.pageSurface(context),
          body: BlocBuilder<TransactionBloc, TransactionState>(
            builder: (context, transactionState) {
              if (transactionState is TransactionLoading) {
                return _buildDashboardSkeleton();
              }

              if (transactionState is TransactionLoaded) {
                final transactions = transactionState.transactions;
                final isEmpty = transactions.isEmpty;
                if (transactions.isNotEmpty && !_onboardingComplete) {
                  _onboardingComplete = true;
                  final authState = context.read<AuthBloc>().state;
                  if (authState is AuthAuthenticated) {
                    OnboardingService().markComplete(authState.user.id);
                  }
                }

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: _dashboardBlue,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(34),
                            bottomRight: Radius.circular(34),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x260079DC),
                              blurRadius: 24,
                              offset: Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            SafeArea(
                              top: true,
                              bottom: false,
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 5, 12, 0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: BlocBuilder<AuthBloc, AuthState>(
                                        builder: (context, state) {
                                          if (state is! AuthAuthenticated) {
                                            return const SizedBox.shrink();
                                          }
                                          return Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(3),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.white
                                                      .withValues(alpha: 0.16),
                                                  border: Border.all(
                                                      color: Colors.white),
                                                ),
                                                child: ListenableBuilder(
                                                  listenable:
                                                      _profilePictureService,
                                                  builder: (context, _) =>
                                                      _profilePictureService
                                                          .buildProfileAvatar(
                                                    displayName:
                                                        state.user.displayName,
                                                    colorScheme: colorScheme,
                                                    radius: 20,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Flexible(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Hi, ${state.user.displayName?.split(' ').first ?? 'there'}',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 17,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                    Text(
                                                      _getGreeting(),
                                                      style: TextStyle(
                                                        color: Colors.white
                                                            .withValues(
                                                                alpha: 0.68),
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                    _buildHeaderAction(
                                      icon: LucideIcons.goal,
                                      tooltip: 'Goals',
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const GoalsScreen(),
                                        ),
                                      ),
                                    ),
                                    BlocBuilder<NotificationsBloc,
                                        NotificationsState>(
                                      builder: (context, state) {
                                        final unreadCount =
                                            state is NotificationsLoaded
                                                ? state.unreadCount
                                                : 0;
                                        return Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            _buildHeaderAction(
                                              icon: LucideIcons.bell,
                                              tooltip: 'Notifications',
                                              onPressed: () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      const NotificationsScreen(),
                                                ),
                                              ),
                                            ),
                                            if (unreadCount > 0)
                                              Positioned(
                                                right: 1,
                                                top: 1,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(2),
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: Colors.red,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  constraints:
                                                      const BoxConstraints(
                                                    minWidth: 16,
                                                    minHeight: 16,
                                                  ),
                                                  child: Text(
                                                    unreadCount > 9
                                                        ? '9+'
                                                        : unreadCount
                                                            .toString(),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
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
                              ),
                            ),
                            _buildBalanceCard(transactions),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Transform.translate(
                          offset: const Offset(0, -22),
                          child: _buildQuickActions(),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FutureBuilder<List<RecurringTransaction>>(
                              future: _recurringTransactionsFuture,
                              builder: (context, recurringSnapshot) {
                                final recurring =
                                    recurringSnapshot.data ?? const [];
                                if (recurring.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return Column(
                                  children: [
                                    _buildUpcomingRecurring(recurring),
                                    const SizedBox(height: 24),
                                  ],
                                );
                              },
                            ),
                            if (isEmpty)
                              _buildFirstRunNudge()
                            else ...[
                              _buildRecentTransactions(transactions),
                              const SizedBox(height: 16),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                );
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingRecurring(
    List<RecurringTransaction> recurringTransactions,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final upcoming = recurringTransactions
        .where((item) =>
            item.isActive &&
            item.nextRunAt.isBefore(now.add(const Duration(days: 30))))
        .toList()
      ..sort((a, b) => a.nextRunAt.compareTo(b.nextRunAt));

    if (upcoming.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.surfaceDecoration(context, subtle: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.repeat, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Coming up',
                  style: AppTheme.sectionTitleStyle(context).copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RecurringTransactionsScreen(),
                  ),
                ),
                child: const Text('Manage'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...upcoming.take(3).map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              item.nextRunAt.isBefore(now)
                                  ? 'Overdue'
                                  : formatShortDate(item.nextRunAt),
                              style: TextStyle(
                                color: item.nextRunAt.isBefore(now)
                                    ? AppColors.error
                                    : colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        CurrencyService().formatAmount(item.amount),
                        style: TextStyle(
                          color: item.type == TransactionType.expense
                              ? AppColors.error
                              : AppColors.success,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildHeaderAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: 19),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.14),
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          fixedSize: const Size(44, 44),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(List<Transaction> transactions) {
    final balance = transactions.netBalance;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 38, 20, 64),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Available balance',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.68),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 7),
              GestureDetector(
                onTap: _toggleBalanceVisibility,
                child: Icon(
                  _isBalanceVisible ? LucideIcons.eye : LucideIcons.eyeOff,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.76),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _isBalanceVisible
                ? CurrencyService().formatAmount(balance)
                : '••••••',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              height: 1.05,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      height: 72,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface(context),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkBorder.withValues(alpha: 0.65)
              : const Color(0xFFE8F1FA),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha:
                  Theme.of(context).brightness == Brightness.dark ? 0.28 : 0.09,
            ),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildActionButton(
              'Add transaction',
              LucideIcons.plus,
              filled: true,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildCircularAction(
            LucideIcons.coins,
            'Add budget',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddBudgetScreen()),
            ),
          ),
          const SizedBox(width: 8),
          _buildCircularAction(
            LucideIcons.goal,
            'Goals',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GoalsScreen()),
            ),
          ),
          const SizedBox(width: 8),
          _buildCircularAction(
            LucideIcons.lineChart,
            'Insights',
            () => context.read<NavigationCubit>().setTab(3),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon, {
    required VoidCallback onTap,
    bool filled = false,
  }) {
    return Material(
      color: filled ? _dashboardBlue : Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: SizedBox(
          height: 52,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: filled ? Colors.white : _dashboardBlue, size: 20),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: filled ? Colors.white : _dashboardBlue,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircularAction(
    IconData icon,
    String tooltip,
    VoidCallback onTap,
  ) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Theme.of(context).colorScheme.tertiary,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildFirstRunNudge() {
    return EmptyStateView(
      icon: _onboardingComplete ? LucideIcons.scrollText : LucideIcons.sparkles,
      iconColor: Theme.of(context).colorScheme.primary,
      title: _onboardingComplete
          ? 'Your transactions will appear here'
          : 'Start with one transaction',
      titleFontSize: 16,
      subtitle: _onboardingComplete
          ? 'Add an income or expense to start building your financial picture.'
          : 'Flux will use it to build your balance, spending history, and insights.',
      actionLabel: 'Add transaction',
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
    final recent = transactions.take(6).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent transactions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            TextButton(
              onPressed: () => context.read<NavigationCubit>().setTab(2),
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('See all'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...recent.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: _CompactTransactionRow(
              item: item,
              onTap: () => context.read<NavigationCubit>().setTab(2),
            ),
          ),
        ),
      ],
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
    final isIncome = item.isIncome;
    final accentColor = isIncome ? AppColors.success : AppColors.error;
    final mutedColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.48);
    final dayLabel = _dayLabel(item.date);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isIncome
                    ? const Color(0xFFEAF8F2)
                    : const Color(0xFFFFF1F0),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isIncome ? LucideIcons.dollarSign : LucideIcons.receipt,
                color: accentColor,
                size: 19,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$dayLabel  •  ${_timeLabel(item.date)}',
                    style: TextStyle(fontSize: 12, color: mutedColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}${CurrencyService().formatAmount(item.amount)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isIncome ? AppColors.successDark : null,
                  ),
                ),
                if (!item.isActive)
                  const Text(
                    'Inactive',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _dayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDay = DateTime(date.year, date.month, date.day);
    final difference = today.difference(itemDay).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference >= 0 && difference < 7) return 'This week';
    return '${date.day}/${date.month}/${date.year}';
  }

  static String _timeLabel(DateTime date) {
    final hour =
        date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
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
