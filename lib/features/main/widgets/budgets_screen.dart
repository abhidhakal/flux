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
import '../../budget/screens/edit_budget_screen.dart';
import '../../../shared/widgets/app_snackbar.dart';

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
    // Load budgets when screen initializes
    final user = context.read<AuthBloc>().state;
    if (user is AuthAuthenticated) {
      context.read<BudgetBloc>().add(LoadBudgets(user.user.id));
    }
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
            icon: Icon(Icons.add_rounded, color: colorScheme.onBackground),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.account_balance_wallet,
            size: 64,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'No Budgets Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first budget to start tracking your spending',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
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
            icon: const Icon(Icons.add),
            label: const Text('Create Budget'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textInverse,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Budgets',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final user = context.read<AuthBloc>().state;
              if (user is AuthAuthenticated) {
                context.read<BudgetBloc>().add(LoadBudgets(user.user.id));
              }
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetsList(List<Budget> budgets) {
    final activeBudgets = budgets.where((budget) => budget.isActive).toList();
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
              child: _buildBudgetCard(budget),
            )),
        if (inactiveBudgets.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildInactiveSectionHeader(inactiveBudgets.length),
          if (_showInactiveBudgets) ...[
            const SizedBox(height: 12),
            ...inactiveBudgets.map((budget) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildBudgetCard(budget, muted: true),
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
                  style: AppTheme.sectionTitleStyle(context).copyWith(fontSize: 20),
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
              child: _buildStatTile(
                label: 'Pool',
                value: CurrencyService().formatAmount(stats.totalBudgetAmount),
                icon: Icons.wallet_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatTile(
                label: 'Spent',
                value: CurrencyService().formatAmount(stats.totalSpentAmount),
                icon: Icons.trending_down_rounded,
                color: AppColors.error,
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
              widthFactor:
                  (stats.utilizationPercentage / 100).clamp(0.0, 1.0),
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
                value: CurrencyService()
                    .formatAmount(stats.totalRemainingAmount),
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

  Widget _buildStatTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.mutedSurface(context) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: isDark ? 0.14 : 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.10 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(Budget budget, {bool muted = false}) {
    final spent = budget.spent;
    final total = budget.totalAvailable;
    final percentage = budget.progressPercentage;
    final isOverBudget = budget.isOverBudget;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine card color based on budget status
    Color cardColor;
    Color borderColor;
    if (muted) {
      cardColor = colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);
      borderColor = colorScheme.outline.withValues(alpha: 0.35);
    } else if (spent <= 0) {
      cardColor = AppColors.primary.withValues(alpha: 0.06);
      borderColor = AppColors.primary.withValues(alpha: 0.28);
    } else if (isOverBudget) {
      cardColor = AppColors.error.withValues(alpha: 0.08);
      borderColor = AppColors.error.withValues(alpha: 0.35);
    } else if (percentage > 80) {
      cardColor = AppColors.warning.withValues(alpha: 0.08);
      borderColor = AppColors.warning.withValues(alpha: 0.3);
    } else {
      cardColor = AppTheme.cardSurface(context);
      borderColor = colorScheme.outline.withValues(alpha: 0.12);
    }

    return InkWell(
      onTap: () => EditBudgetScreen.showEditBudgetSheet(context, budget),
      borderRadius: BorderRadius.circular(AppTheme.radius16),
      child: Card(
        margin: EdgeInsets.zero, // Card margin handled by ListView separator
        elevation: 0,
        color: cardColor,
        shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius20),
        side: BorderSide(
          color: borderColor,
          width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with icon and title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacing8),
                    decoration: BoxDecoration(
                      color: muted
                          ? colorScheme.outline.withValues(alpha: 0.15)
                          : isOverBudget
                              ? AppColors.error.withValues(alpha: 0.1)
                              : percentage > 80
                                  ? AppColors.warning.withValues(alpha: 0.1)
                                  : AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radius8),
                    ),
                    child: Icon(
                      muted
                          ? Icons.pause_circle_filled_rounded
                          : isOverBudget
                              ? Icons.warning
                              : percentage > 80
                                  ? Icons.trending_up_rounded
                                  : Icons.wallet_rounded,
                      color: muted
                          ? colorScheme.onSurface.withValues(alpha: 0.65)
                          : isOverBudget
                              ? AppColors.error
                              : percentage > 80
                                  ? AppColors.warning
                                  : AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          budget.name,
                          style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface
                              .withValues(alpha: muted ? 0.7 : 1),
                        ),
                        ),
                        Row(
                          children: [
                            Text(
                              '${budget.category} • ${budget.period.name.toUpperCase()}',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                            if (!budget.isActive) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorScheme.outline
                                      .withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Inactive',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.75),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showDeleteBudgetDialog(budget),
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.error),
                    tooltip: 'Delete Budget',
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing8),
              // Amount row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${CurrencyService().formatAmount(spent)} / ${CurrencyService().formatAmount(total)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: muted
                          ? colorScheme.onSurface.withValues(alpha: 0.7)
                          : isOverBudget
                              ? AppColors.error
                              : colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: (percentage / 100).clamp(0.0, 1.0),
                backgroundColor: colorScheme.outline.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  muted
                      ? colorScheme.onSurface.withValues(alpha: 0.3)
                      : isOverBudget
                          ? AppColors.error
                          : AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${percentage.toStringAsFixed(1)}% used',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: muted
                          ? colorScheme.onSurface.withValues(alpha: 0.65)
                          : isOverBudget
                              ? AppColors.error
                              : colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                  Text(
                    '${CurrencyService().formatAmount(total - spent)} remaining',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              if (isOverBudget && !muted)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Over budget by ${CurrencyService().formatAmount(spent - total)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              if (budget.hasRollover)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Includes ${CurrencyService().formatAmount(budget.rolloverAmount)} rollover',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // _showCreateBudgetDialog removed — use AddBudgetScreen page instead

  // _showEditBudgetDialog removed — use EditBudgetScreen.showEditBudgetSheet instead

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
                Icons.archive_rounded,
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
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: AppTheme.cardSurface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.12), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.warning),
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
    final budgetBloc = context.read<BudgetBloc>();

    if (user is AuthAuthenticated) {
      // Recalculate budget spent amounts - this will automatically reload budgets when complete
      budgetBloc.add(RecalculateBudgetSpent(user.user.id));
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

  const _BudgetStats({
    required this.totalBudgetAmount,
    required this.totalSpentAmount,
    required this.totalRemainingAmount,
    required this.utilizationPercentage,
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

    return _BudgetStats(
      totalBudgetAmount: totalBudgetAmount,
      totalSpentAmount: totalSpentAmount,
      totalRemainingAmount: totalRemainingAmount,
      utilizationPercentage: utilizationPercentage,
    );
  }
}
