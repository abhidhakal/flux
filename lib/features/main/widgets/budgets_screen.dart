import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/models/budget_model.dart';
import '../../../core/services/currency_service.dart';
import '../../../core/services/planning_insights_service.dart';
import '../../../core/services/adaptive_budget_service.dart';
import '../../../shared/widgets/skeleton_components.dart';
import '../../auth/auth_bloc.dart';
import '../../budget/budget_bloc.dart';
import '../../budget/screens/add_budget_screen.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/premium_page_hero.dart';
import 'budget_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  bool _showInactiveBudgets = false;
  final PlanningInsightsService _planning = PlanningInsightsService();
  final AdaptiveBudgetService _adaptiveBudget = AdaptiveBudgetService();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppTheme.pageSurface(context),
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
      ),
    );
  }

  Widget _buildBudgetHero({int? activeCount}) {
    return PremiumPageHero(
      title: 'Budgets',
      subtitle: activeCount == null
          ? 'Plan your spending with intention'
          : '$activeCount active ${activeCount == 1 ? 'budget' : 'budgets'}',
      actions: [
        PremiumPageHeroAction(
          icon: LucideIcons.refreshCw,
          tooltip: 'Recalculate budget totals from transactions',
          onPressed: _recalculateBudgetTotals,
        ),
        const SizedBox(width: 8),
        PremiumPageHeroAction(
          icon: LucideIcons.plus,
          tooltip: 'Add budget',
          onPressed: _openAddBudget,
        ),
      ],
    );
  }

  void _recalculateBudgetTotals() {
    final user = context.read<AuthBloc>().state;
    if (user is AuthAuthenticated) {
      context.read<BudgetBloc>().add(RecalculateBudgetSpent(user.user.id));
    }
  }

  void _openAddBudget() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<BudgetBloc>()),
            BlocProvider.value(value: context.read<AuthBloc>()),
          ],
          child: const AddBudgetScreen(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 120),
      children: [
        _buildBudgetHero(),
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.52,
          child: EmptyStateView(
            icon: LucideIcons.coins,
            iconColor: AppColors.primary,
            title: 'No Budgets Yet',
            titleFontSize: 24,
            subtitle:
                'Create your first budget to start tracking your spending',
            actionLabel: 'Create Budget',
            actionIcon: LucideIcons.plus,
            spacingBeforeAction: 24,
            actionStyle: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textInverse,
            ),
            onAction: _openAddBudget,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String message) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 120),
      children: [
        _buildBudgetHero(),
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.52,
          child: EmptyStateView(
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
          ),
        ),
      ],
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
      padding: const EdgeInsets.only(bottom: 120),
      children: [
        _buildBudgetHero(activeCount: activeBudgets.length),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
          child: _buildOverviewCards(
            stats: stats,
            activeCount: activeBudgets.length,
            inactiveCount: inactiveBudgets.length,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              _buildForecastCard(activeBudgets),
              _buildAdaptivePlanCard(activeBudgets),
              _buildSectionHeading(
                title: 'Active Budgets',
                subtitle: '',
                count: activeBudgets.length,
              ),
              if (activeBudgets.isEmpty)
                _buildNoActiveBudgetsCard(
                    inactiveCount: inactiveBudgets.length),
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildForecastCard(List<Budget> budgets) {
    final forecasts = _planning.forecastBudgets(budgets);
    if (forecasts.isEmpty) return const SizedBox.shrink();
    final forecast = forecasts.first;
    final colorScheme = Theme.of(context).colorScheme;
    final atRisk = forecast.likelyOverBudget;
    final title =
        atRisk ? 'Budget forecast needs attention' : 'Budget forecast';
    final detail = atRisk
        ? '${forecast.budget.name} may exceed its limit by ${CurrencyService().formatAmount(forecast.projectedOverage)}.'
        : 'Your current pace keeps ${forecast.budget.name} within its limit.';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (atRisk ? AppColors.warning : AppColors.primary)
            .withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (atRisk ? AppColors.warning : AppColors.primary)
              .withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        children: [
          Icon(atRisk ? LucideIcons.alertTriangle : LucideIcons.trendingUp,
              color: atRisk ? AppColors.warning : AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(detail,
                    style: TextStyle(
                        color: colorScheme.onSurfaceVariant, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdaptivePlanCard(List<Budget> budgets) {
    final insights = _adaptiveBudget.analyzeAll(budgets);
    if (insights.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final weeklySafeSpend = insights.fold<double>(
      0,
      (total, insight) => total + insight.weeklySafeSpend,
    );
    final priority = insights.first;
    final isAttention = priority.needsAttention;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isAttention ? AppColors.warning : AppColors.success)
            .withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (isAttention ? AppColors.warning : AppColors.success)
              .withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAttention ? LucideIcons.shieldAlert : LucideIcons.gauge,
                color: isAttention ? AppColors.warning : AppColors.success,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Adaptive spending plan',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Text(
                '${CurrencyService().formatAmount(weeklySafeSpend)} / week',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Recommended weekly spending across your active budgets.',
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.65),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            priority.recommendation,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          if (priority.daysRemaining > 0) ...[
            const SizedBox(height: 8),
            Text(
              '${priority.budget.name}: ${CurrencyService().formatAmount(priority.dailySafeSpend)} per day remaining',
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.65),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
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
      padding: const EdgeInsets.only(top: 28, bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.sectionTitleStyle(context).copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle.isEmpty ? 'Keep every plan within reach' : subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
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
        const SizedBox(height: 12),
        _buildBudgetMetrics(stats),
      ],
    );
  }

  Widget _buildBudgetMetrics(_BudgetStats stats) {
    final statusColor =
        stats.overBudgetCount > 0 ? AppColors.error : AppColors.success;

    return Row(
      children: [
        Expanded(
          child: _buildBudgetMetric(
            icon: LucideIcons.coins,
            label: 'Total planned',
            value: CurrencyService().formatAmount(stats.totalBudgetAmount),
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildBudgetMetric(
            icon: stats.overBudgetCount > 0
                ? LucideIcons.alertTriangle
                : LucideIcons.circleCheck,
            label: stats.overBudgetCount > 0 ? 'Needs attention' : 'On track',
            value: stats.overBudgetCount > 0
                ? '${stats.overBudgetCount} over budget'
                : 'All budgets healthy',
            color: statusColor,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 82),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.56),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

    final utilization = (stats.utilizationPercentage / 100).clamp(0.0, 1.0);
    final totalOver = stats.totalRemainingAmount < 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  LucideIcons.chartNoAxesCombined,
                  color: AppColors.primary,
                  size: 19,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Budget health',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Across your active plans',
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.55),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _heroTag(
                label: '$activeCount active',
                color: AppColors.primary,
                textColor: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 82,
                height: 82,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 82,
                      height: 82,
                      child: CircularProgressIndicator(
                        value: utilization,
                        strokeWidth: 8,
                        strokeCap: StrokeCap.round,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          utilizationColor,
                        ),
                      ),
                    ),
                    Text(
                      '${stats.utilizationPercentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      totalOver
                          ? 'Spending is above plan'
                          : 'Spending is on track',
                      style: TextStyle(
                        color: totalOver ? AppColors.error : AppColors.success,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${CurrencyService().formatAmount(stats.totalSpentAmount)} spent of ${CurrencyService().formatAmount(stats.totalBudgetAmount)} planned',
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.62),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _heroMeta(
                label: 'Spent',
                value: CurrencyService().formatAmount(stats.totalSpentAmount),
                textColor: colorScheme.onSurface,
              ),
              _heroMeta(
                label: stats.totalRemainingAmount < 0 ? 'Over budget' : 'Left',
                value: CurrencyService().formatAmount(
                  stats.totalRemainingAmount,
                ),
                textColor: stats.totalRemainingAmount < 0
                    ? AppColors.error
                    : colorScheme.onSurface,
                alignEnd: true,
              ),
            ],
          ),
          if (inactiveCount > 0) ...[
            const SizedBox(height: 12),
            Text(
              '$inactiveCount inactive ${inactiveCount == 1 ? 'budget' : 'budgets'} not included',
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.48),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
    bool alignEnd = false,
  }) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
      decoration:
          AppTheme.surfaceDecoration(context, radius: AppTheme.cardRadius),
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
      padding: const EdgeInsets.only(bottom: 120),
      children: [
        _buildBudgetHero(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
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
                  SkeletonComponents.textLine(
                      width: double.infinity, height: 8),
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
          ),
        ),
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
