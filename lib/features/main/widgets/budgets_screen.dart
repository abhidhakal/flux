import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/models/budget_model.dart';
import '../../../core/services/currency_service.dart';
import '../../../shared/widgets/skeleton_components.dart';
import '../../../core/widgets/app_banner_ad.dart';
import '../../auth/auth_bloc.dart';
import '../../budget/budget_bloc.dart';
import '../../budget/screens/add_budget_screen.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/stat_tile.dart';
import '../../../shared/widgets/empty_state_view.dart';
import 'budget_card.dart';
import 'package:lucide_icons/lucide_icons.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  bool _showInactiveBudgets = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: AppTheme.pageBackground(context),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Budgets'),
        centerTitle: false,
        backgroundColor: AppTheme.pageBackground(context),
        foregroundColor: colorScheme.onBackground,
        iconTheme: IconThemeData(color: colorScheme.onBackground),
        titleTextStyle: theme.textTheme.displaySmall?.copyWith(
          fontSize: 24,
          letterSpacing: -1,
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: Icon(LucideIcons.refreshCw,
                color: colorScheme.onBackground, size: 20),
            tooltip: 'Recalculate budget totals from transactions',
            onPressed: () {
              final user = context.read<AuthBloc>().state;
              if (user is AuthAuthenticated) {
                context
                    .read<BudgetBloc>()
                    .add(RecalculateBudgetSpent(user.user.id));
              }
            },
          ),
          IconButton(
            icon: Icon(LucideIcons.plus, color: colorScheme.onBackground),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => MultiBlocProvider(
                        providers: [
                          BlocProvider.value(value: context.read<BudgetBloc>()),
                          BlocProvider.value(value: context.read<AuthBloc>()),
                        ],
                        child: const AddBudgetScreen(),
                      )),
            ),
          ),
        ],
      ),
      body: BlocListener<BudgetBloc, BudgetState>(
        listener: (context, state) {
          if (state is BudgetSuccess) {
            AppSnackbar.showSuccess(context, message: state.message);
            // Reload budgets after successful operation
            final user = context.read<AuthBloc>().state;
            if (user is AuthAuthenticated) {
              context.read<BudgetBloc>().add(LoadBudgets(user.user.id));
            }
          }

          if (state is BudgetError) {
            AppSnackbar.showError(context, message: state.message);
          }
        },
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: BlocBuilder<BudgetBloc, BudgetState>(
            builder: (context, state) {
              if (state is BudgetLoading) {
                return _buildBudgetsSkeleton();
              }

              if (state is BudgetLoaded) {
                if (state.budgets.isEmpty) {
                  return _buildEmptyState();
                }
                return _buildBudgetsList(state.budgets);
              }

              if (state is BudgetError) {
                return _buildErrorState(state.message);
              }

              return _buildEmptyState();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return EmptyStateView(
      icon: LucideIcons.wallet,
      iconColor: AppColors.primary,
      title: 'No Budgets Yet',
      titleFontSize: 24,
      subtitle: 'Create your first budget to start tracking your spending',
      actionLabel: 'Create Budget',
      actionIcon: LucideIcons.plus,
      spacingBeforeAction: 24,
      actionStyle: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textInverse,
      ),
      onAction: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => MultiBlocProvider(
                  providers: [
                    BlocProvider.value(value: context.read<BudgetBloc>()),
                    BlocProvider.value(value: context.read<AuthBloc>()),
                  ],
                  child: const AddBudgetScreen(),
                )),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return EmptyStateView(
      icon: LucideIcons.alertCircle,
      iconColor: AppColors.error,
      title: 'Error Loading Budgets',
      subtitle: message,
      actionLabel: 'Retry',
      onAction: () {
        final user = context.read<AuthBloc>().state;
        if (user is AuthAuthenticated) {
          context.read<BudgetBloc>().add(LoadBudgets(user.user.id));
        }
      },
    );
  }

  Widget _buildBudgetsList(List<Budget> budgets) {
    final activeBudgets = budgets.where((budget) => budget.isActive).toList()
      ..sort((a, b) => b.progressPercentage.compareTo(a.progressPercentage));
    final inactiveBudgets =
        budgets.where((budget) => !budget.isActive).toList();
    final stats = _BudgetStats.fromBudgets(activeBudgets);

    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.only(bottom: 120, left: 16, right: 16, top: 16),
      children: [
        _buildOverviewCards(
          stats: stats,
          activeCount: activeBudgets.length,
          inactiveCount: inactiveBudgets.length,
        ),
        _buildSectionHeading(
          title: 'Active Budgets',
          subtitle: '',
          count: activeBudgets.length,
        ),
        if (activeBudgets.isEmpty)
          _buildNoActiveBudgetsCard(inactiveCount: inactiveBudgets.length),
        ...activeBudgets.map((budget) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: BudgetCard(
                budget: budget,
                onDelete: () => _showDeleteBudgetDialog(budget),
              ),
            )),
        if (inactiveBudgets.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildInactiveSectionHeader(inactiveBudgets.length),
          if (_showInactiveBudgets) ...[
            const SizedBox(height: 12),
            ...inactiveBudgets.map((budget) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: BudgetCard(
                    budget: budget,
                    muted: true,
                    onDelete: () => _showDeleteBudgetDialog(budget),
                  ),
                )),
          ],
        ],
        const Padding(
          padding: EdgeInsets.only(top: 24),
          child: AppBannerAd(),
        ),
      ],
    );
  }

  Widget _buildSectionHeading({
    required String title,
    required String subtitle,
    required int count,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.sectionTitleStyle(context)
                      .copyWith(fontSize: 20),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards({
    required _BudgetStats stats,
    required int activeCount,
    required int inactiveCount,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBudgetHealthHero(
          stats: stats,
          activeCount: activeCount,
          inactiveCount: inactiveCount,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: 'Budgeted',
                value: CurrencyService().formatAmount(stats.totalBudgetAmount),
                icon: LucideIcons.landmark,
                accentColor: AppColors.primary,
                direction: Axis.horizontal,
                bordered: true,
                radius: 16,
                padding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                label: 'Over Budget',
                value: '${stats.overBudgetCount}',
                icon: LucideIcons.alertTriangle,
                accentColor: stats.overBudgetCount > 0
                    ? AppColors.error
                    : AppColors.success,
                direction: Axis.horizontal,
                bordered: true,
                radius: 16,
                padding: const EdgeInsets.all(14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildBudgetHealthHero({
    required _BudgetStats stats,
    required int activeCount,
    required int inactiveCount,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color utilizationColor;
    if (stats.utilizationPercentage >= 90) {
      utilizationColor = AppColors.error;
    } else if (stats.utilizationPercentage >= 75) {
      utilizationColor = AppColors.warning;
    } else {
      utilizationColor = AppColors.success;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.surfaceDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Budget Health',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              _heroTag(
                label: '$activeCount active',
                color: AppColors.primary,
                textColor: colorScheme.onSurface,
              ),
              if (inactiveCount > 0) ...[
                const SizedBox(width: 8),
                _heroTag(
                  label: '$inactiveCount inactive',
                  color: AppColors.warning,
                  textColor: colorScheme.onSurface,
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${stats.utilizationPercentage.toStringAsFixed(1)}%',
            style: theme.textTheme.headlineLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Spend visibility across your active budgets.',
            style: AppTheme.sectionSubtitleStyle(context),
          ),
          const SizedBox(height: 10),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: colorScheme.outline.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(99),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (stats.utilizationPercentage / 100).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: utilizationColor,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _heroMeta(
                label: 'Spent',
                value: CurrencyService().formatAmount(stats.totalSpentAmount),
                textColor: colorScheme.onSurface,
              ),
              _heroMeta(
                label: 'Remaining',
                value:
                    CurrencyService().formatAmount(stats.totalRemainingAmount),
                textColor: colorScheme.onSurface,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroTag({
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor.withValues(alpha: 0.9),
        ),
      ),
    );
  }

  Widget _heroMeta({
    required String label,
    required String value,
    required Color textColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textColor.withValues(alpha: 0.65),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildInactiveSectionHeader(int count) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() {
            _showInactiveBudgets = !_showInactiveBudgets;
          });
        },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: AppTheme.cardSurface(context),
            border:
                Border.all(color: colorScheme.outline.withValues(alpha: 0.14)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                LucideIcons.archive,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Inactive Budgets',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: colorScheme.outline.withValues(alpha: 0.12),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                _showInactiveBudgets
                    ? LucideIcons.chevronUp
                    : LucideIcons.chevronDown,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoActiveBudgetsCard({required int inactiveCount}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.surfaceDecoration(context, radius: 20),
      child: Row(
        children: [
          const Icon(LucideIcons.info, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              inactiveCount > 0
                  ? 'All budgets are inactive. Reactivate one to include it in utilization.'
                  : 'Create your first active budget to see utilization stats.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteBudgetDialog(Budget budget) {
    final budgetBloc = context.read<BudgetBloc>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final colorScheme = Theme.of(sheetContext).colorScheme;
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outline.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Delete Budget',
                  style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Delete "${budget.name}" permanently? This cannot be undone.',
                  style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.75),
                      ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.onSurface,
                          side: BorderSide(
                            color: colorScheme.outline.withValues(alpha: 0.35),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          budgetBloc.add(DeleteBudget(budget.id));
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: colorScheme.onError,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Delete'),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                    height: MediaQuery.of(sheetContext).viewPadding.bottom),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _onRefresh() async {
    final user = context.read<AuthBloc>().state;
    if (user is AuthAuthenticated) {
      context.read<BudgetBloc>().add(LoadBudgets(user.user.id));
    }
  }

  Widget _buildBudgetsSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Overview cards skeleton
        SkeletonComponents.card(
          height: 100,
          children: [
            Row(
              children: [
                SkeletonComponents.circle(size: 48, context: context),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonComponents.textLine(width: 100, height: 14),
                      const SizedBox(height: 4),
                      SkeletonComponents.textLine(width: 80, height: 20),
                      const SizedBox(height: 2),
                      SkeletonComponents.textLine(width: 60, height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ],
          context: context,
        ),
        const SizedBox(height: 12),

        // Progress card skeleton
        SkeletonComponents.card(
          height: 140,
          children: [
            Row(
              children: [
                SkeletonComponents.circle(size: 48, context: context),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonComponents.textLine(width: 120, height: 14),
                      const SizedBox(height: 4),
                      SkeletonComponents.textLine(width: 60, height: 20),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SkeletonComponents.textLine(width: double.infinity, height: 8),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonComponents.textLine(width: 40, height: 12),
                    SkeletonComponents.textLine(width: 60, height: 14),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SkeletonComponents.textLine(width: 50, height: 12),
                    SkeletonComponents.textLine(width: 70, height: 14),
                  ],
                ),
              ],
            ),
          ],
          context: context,
        ),
        const SizedBox(height: 12),

        // Total spending card skeleton
        SkeletonComponents.card(
          height: 100,
          children: [
            Row(
              children: [
                SkeletonComponents.circle(size: 48, context: context),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonComponents.textLine(width: 100, height: 14),
                      const SizedBox(height: 4),
                      SkeletonComponents.textLine(width: 80, height: 20),
                      const SizedBox(height: 2),
                      SkeletonComponents.textLine(width: 60, height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ],
          context: context,
        ),
        const SizedBox(height: 16),

        // Heading skeleton
        SkeletonComponents.textLine(width: 120, height: 20),
        const SizedBox(height: 16),

        // Budget cards skeleton
        ...List.generate(
            3,
            (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SkeletonComponents.budgetCard(context: context),
                )),
      ],
    );
  }
}

class _BudgetStats {
  final double totalBudgetAmount;
  final double totalSpentAmount;
  final double totalRemainingAmount;
  final double utilizationPercentage;
  final int overBudgetCount;

  const _BudgetStats({
    required this.totalBudgetAmount,
    required this.totalSpentAmount,
    required this.totalRemainingAmount,
    required this.utilizationPercentage,
    required this.overBudgetCount,
  });

  factory _BudgetStats.fromBudgets(List<Budget> budgets) {
    final totalBudgetAmount =
        budgets.fold<double>(0, (sum, budget) => sum + budget.amount);
    final totalSpentAmount =
        budgets.fold<double>(0, (sum, budget) => sum + budget.spent);
    final totalRemainingAmount = totalBudgetAmount - totalSpentAmount;
    final utilizationPercentage = totalBudgetAmount > 0
        ? (totalSpentAmount / totalBudgetAmount) * 100
        : 0.0;
    final overBudgetCount = budgets.where((b) => b.isOverBudget).length;

    return _BudgetStats(
      totalBudgetAmount: totalBudgetAmount,
      totalSpentAmount: totalSpentAmount,
      totalRemainingAmount: totalRemainingAmount,
      utilizationPercentage: utilizationPercentage,
      overBudgetCount: overBudgetCount,
    );
  }
}
