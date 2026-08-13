import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/models/financial_snapshot.dart';
import '../../../core/models/ai_financial_context.dart';
import '../../../core/models/budget_model.dart';
import '../../../core/models/goal_model.dart';
import '../../../core/services/currency_service.dart';
import '../../../core/services/ai_insight_service.dart';
import '../../auth/auth_bloc.dart';
import '../../transaction/transaction_bloc.dart';
import '../../budget/budget_bloc.dart';
import '../../goals/goals_bloc.dart';
import '../analytics_bloc.dart';
import '../widgets/category_breakdown_chart.dart';
import '../widgets/trend_analysis_chart.dart';
import '../widgets/weekly_spending_chart.dart';
import '../widgets/for_you_actions_card.dart';
import '../../../core/utils/date_range_filter.dart';
import '../../../shared/widgets/stat_tile.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/app_section_header.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_snackbar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  TimelineFilter _timelineFilter = TimelineFilter.lastMonth;
  DateTimeRange? _customRange;
  bool _showMonthlyTrend = false;
  bool _isAiLoading = false;
  AiInsightResult? _aiResult;

  @override
  void initState() {
    super.initState();
  }

  DateTimeRange _getActiveRange() =>
      activeRangeFor(_timelineFilter, customRange: _customRange);

  Future<void> _pickCustomRange() async {
    final picked = await pickCustomRange(context, _customRange);
    if (picked != null) {
      setState(() {
        _customRange = picked;
        _timelineFilter = TimelineFilter.custom;
      });
    }
  }

  List<Transaction> _filterTransactions(List<Transaction> transactions) {
    final range = _getActiveRange();
    return transactions.where((t) => isWithinRange(t.date, range)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: AppTheme.pageBackground(context),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Insights'),
        centerTitle: false,
        backgroundColor: AppTheme.pageBackground(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: theme.textTheme.displaySmall?.copyWith(
          fontSize: 24,
          letterSpacing: -1,
        ),
        actions: [
          _buildPeriodSelector(colorScheme),
          const SizedBox(width: 16),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<TransactionBloc, TransactionState>(
            listener: (context, state) {
              if (state is TransactionLoaded) {
                context.read<AnalyticsBloc>().add(
                      AnalyzeSpendingPatterns(state.transactions),
                    );
              }
            },
          ),
        ],
        child: BlocBuilder<TransactionBloc, TransactionState>(
          builder: (context, transactionState) {
            if (transactionState is TransactionLoading) {
              return _buildLoadingState();
            }

            if (transactionState is TransactionLoaded) {
              final allTransactions = transactionState.transactions;
              final transactions = _filterTransactions(allTransactions);
              final budgetState = context.watch<BudgetBloc>().state;
              final goalsState = context.watch<GoalsBloc>().state;
              final financialSnapshot = FinancialSnapshot.fromData(
                transactions: allTransactions,
                budgets: budgetState is BudgetLoaded ? budgetState.budgets : [],
                goals: goalsState is GoalsLoaded ? goalsState.goals : [],
              );

              return BlocBuilder<AnalyticsBloc, AnalyticsState>(
                builder: (context, analyticsState) {
                  final analysis = analyticsState is SpendingAnalysisLoaded
                      ? analyticsState.analysis
                      : null;

                  return RefreshIndicator(
                    onRefresh: () async {
                      final user = context.read<AuthBloc>().state;
                      if (user is AuthAuthenticated) {
                        context
                            .read<TransactionBloc>()
                            .add(LoadTransactions(user.user.id));
                      }
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(
                          left: 20, right: 20, top: 8, bottom: 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHealthScoreSection(analysis),
                          const SizedBox(height: 24),
                          ForYouActionsCard(
                            snapshot: financialSnapshot,
                            budgets: budgetState is BudgetLoaded
                                ? budgetState.budgets
                                : const [],
                            goals: goalsState is GoalsLoaded
                                ? goalsState.goals
                                : const [],
                          ),
                          const SizedBox(height: 12),
                          _buildAskFluxAction(
                            transactions: transactions,
                            budgets: budgetState is BudgetLoaded
                                ? budgetState.budgets
                                : const [],
                            goals: goalsState is GoalsLoaded
                                ? goalsState.goals
                                : const [],
                          ),
                          if (_aiResult != null) ...[
                            const SizedBox(height: 12),
                            _buildAiResultCard(_aiResult!),
                          ],
                          const SizedBox(height: 24),
                          _buildQuickStats(transactions),
                          const SizedBox(height: 24),
                          _buildEfficiencySection(analysis),
                          const SizedBox(height: 24),
                          _buildSmartInsightsSection(analyticsState),
                          const SizedBox(height: 24),
                          _buildSubscriptionsSection(analysis),
                          const SizedBox(height: 24),
                          _buildTrendSection(transactions),
                          const SizedBox(height: 24),
                          _buildWealthProjectionSection(analysis),
                          const SizedBox(height: 24),
                          _buildSectionHeader(
                              'Category Breakdown', 'Where your money goes'),
                          const SizedBox(height: 16),
                          CategoryBreakdownChart(transactions: transactions),
                          const SizedBox(height: 24),
                          _buildRecommendationsSection(analysis),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  );
                },
              );
            }

            return _buildEmptyState();
          },
        ),
      ),
    );
  }

  Widget _buildAskFluxAction({
    required List<Transaction> transactions,
    required List<Budget> budgets,
    required List<Goal> goals,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final gradientEnd = Color.lerp(colorScheme.primary, Colors.black, 0.18)!;
    void onAsk() {
      _askFlux(
        transactions: transactions,
        budgets: budgets,
        goals: goals,
      );
    }

    return Semantics(
      button: true,
      label: _isAiLoading ? 'Flux is thinking' : 'Ask Flux for an insight',
      child: Opacity(
        opacity: _isAiLoading ? 0.72 : 1,
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, gradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.22),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: InkWell(
              onTap: _isAiLoading ? null : onAsk,
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 48,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isAiLoading)
                      const SizedBox.square(
                        dimension: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else
                      const Icon(
                        LucideIcons.sparkles,
                        size: 17,
                        color: Colors.white,
                      ),
                    const SizedBox(width: 9),
                    Text(
                      _isAiLoading ? 'Thinking…' : 'Ask Flux',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (!_isAiLoading) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        LucideIcons.arrowUpRight,
                        size: 16,
                        color: Colors.white,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _askFlux({
    required List<Transaction> transactions,
    required List<Budget> budgets,
    required List<Goal> goals,
  }) async {
    final consented = await _confirmAiSharing();
    if (!consented || !mounted) return;

    setState(() => _isAiLoading = true);
    try {
      final currencyService = CurrencyService();
      await currencyService.ensureInitialized();
      final context = AiFinancialContext.fromData(
        currencyCode: currencyService.currency,
        currencySymbol: currencyService.symbol,
        currencyDecimalPlaces: currencyService.decimalPlaces,
        transactions: transactions,
        budgets: budgets,
        goals: goals,
      );
      final result = await AiInsightService().generate(context);
      if (!mounted) return;
      setState(() {
        _aiResult = result;
        _isAiLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isAiLoading = false);
      AppSnackbar.showError(
        context,
        message:
            'Flux AI is unavailable right now. Your local insights are still available.',
      );
    }
  }

  Future<bool> _confirmAiSharing() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ask Flux with AI?'),
        content: const Text(
          'Flux will send anonymous financial totals and category summaries to generate this answer. Transaction names, notes, IDs, and raw records stay on your device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    return result == true;
  }

  Widget _buildAiResultCard(AiInsightResult result) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppCard(
      tint: colorScheme.primary,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.sparkles, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                'AI',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            result.summary,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          for (final action in result.actions) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.arrowRight,
                    size: 16, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${action.label}: ',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: action.reason),
                      ],
                    ),
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (result.caution.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              result.caution,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHealthScoreSection(Map<String, dynamic>? analysis) {
    final score = analysis?['healthScore'] ?? 0;
    final color = score > 80
        ? AppColors.success
        : (score > 50 ? Colors.orange : AppColors.error);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final cardBorderColor = isDark
        ? colorScheme.outline.withValues(alpha: 0.45)
        : color.withValues(alpha: 0.2);
    final progressTrackColor = isDark
        ? colorScheme.outline.withValues(alpha: 0.25)
        : color.withValues(alpha: 0.1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.tintedSurfaceDecoration(
        context,
        tint: color,
        radius: 32,
      ).copyWith(
        border: Border.all(color: cardBorderColor),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 80,
                width: 80,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 8,
                  backgroundColor: progressTrackColor,
                  color: color,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Financial Health Score',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getHealthStatus(score),
                  style: TextStyle(
                    fontSize: 14,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your score combines savings rate, spending efficiency, and recent trend.',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                if (analysis != null) ...[
                  const SizedBox(height: 10),
                  _buildHealthDrivers(analysis, colorScheme),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthDrivers(
      Map<String, dynamic> analysis, ColorScheme colorScheme) {
    final savingsRate = (analysis['savingsRate'] as num?)?.toDouble();
    final efficiency = analysis['efficiency'] as Map<String, dynamic>?;
    final wants = (efficiency?['wants'] as num?)?.toDouble();
    final trend = analysis['spendingTrend'] as String?;
    final trendLabel = switch (trend) {
      'increasing' => 'Spending rising',
      'decreasing' => 'Spending falling',
      _ => 'Spending stable',
    };
    final labels = <String>[
      if (savingsRate != null) 'Savings ${savingsRate.toStringAsFixed(0)}%',
      if (wants != null) 'Wants ${wants.toStringAsFixed(0)}%',
      trendLabel,
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: labels
          .map(
            (label) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  String _getHealthStatus(int score) {
    if (score > 80) return 'Excellent habits!';
    if (score > 60) return 'Solid foundation';
    if (score > 40) return 'Needs attention';
    return 'Critical review needed';
  }

  Widget _buildEfficiencySection(Map<String, dynamic>? analysis) {
    final efficiency = analysis?['efficiency'] as Map<String, dynamic>? ??
        {'needs': 0.0, 'wants': 0.0, 'savings': 0.0};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
            'Spending Efficiency', 'Adherence to the 50/30/20 rule'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.surfaceDecoration(context),
          child: Column(
            children: [
              _buildEfficiencyRow(
                  'Needs (Fixed)', efficiency['needs'], 50, AppColors.primary),
              const SizedBox(height: 16),
              _buildEfficiencyRow(
                  'Wants (Lifestyle)', efficiency['wants'], 30, Colors.orange),
              const SizedBox(height: 16),
              _buildEfficiencyRow('Savings (Wealth)', efficiency['savings'], 20,
                  AppColors.success),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEfficiencyRow(
      String label, dynamic value, double target, Color color) {
    final double val = (value as num).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            Text('${val.toStringAsFixed(1)}% / $target%',
                style: TextStyle(
                    fontSize: 12, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: val / 100,
            backgroundColor: color.withValues(alpha: 0.1),
            color: color,
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionsSection(Map<String, dynamic>? analysis) {
    final subscriptions = analysis?['subscriptions'] as List<dynamic>? ?? [];
    if (subscriptions.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
            'Detected Subscriptions', 'Recurring monthly payments identified'),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: subscriptions.length,
            itemBuilder: (context, index) {
              final sub = subscriptions[index];
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.mutedSurface(context) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(
                          alpha: isDark ? 0.14 : 0.08,
                        ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sub['title'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const Spacer(),
                    Text(
                      CurrencyService().formatAmount(sub['amount'] as double),
                      style: const TextStyle(
                          color: AppColors.error, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      sub['category'],
                      style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWealthProjectionSection(Map<String, dynamic>? analysis) {
    final projected = analysis?['projectedSavings'] as double? ?? 0.0;
    if (projected <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.tintedSurfaceDecoration(
        context,
        tint: AppColors.primary,
        radius: 32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.rocket,
              color: Theme.of(context).colorScheme.onSurface, size: 32),
          const SizedBox(height: 16),
          Text(
            'Wealth Projection',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep up your current habits, and you\'ll have an extra ${CurrencyService().formatAmount(projected)} in 6 months.',
            style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.72),
                fontSize: 14),
          ),
          const SizedBox(height: 16),
          _buildProjectionComparison()
        ],
      ),
    );
  }

  Widget _buildProjectionComparison() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(LucideIcons.trendingUp, color: AppColors.primary, size: 16),
          SizedBox(width: 8),
          Text(
            'Trajectory: High Growth',
            style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // Weekly and monthly trend charts covered overlapping ground as two
  // permanent sections - one toggleable card halves that footprint.
  Widget _buildTrendSection(List<Transaction> transactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader(
              'Spending Trend',
              _showMonthlyTrend
                  ? 'Income vs expenses by month'
                  : 'Your weekly expense activity',
            ),
            _buildTrendToggle(),
          ],
        ),
        const SizedBox(height: 16),
        _showMonthlyTrend
            ? TrendAnalysisChart(transactions: transactions)
            : WeeklySpendingChart(transactions: transactions),
      ],
    );
  }

  Widget _buildTrendToggle() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppTheme.mutedSurface(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _trendToggleOption('Weekly', !_showMonthlyTrend),
          _trendToggleOption('Monthly', _showMonthlyTrend),
        ],
      ),
    );
  }

  Widget _trendToggleOption(String label, bool selected) {
    return GestureDetector(
      onTap: () => setState(() => _showMonthlyTrend = label == 'Monthly'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected
                ? Colors.white
                : Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(List<Transaction> transactions) {
    final expenses = transactions.totalExpenses();
    final totalIncome = transactions.totalIncome();

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Income',
            totalIncome,
            LucideIcons.arrowDownLeft,
            AppColors.success,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Expenses',
            expenses,
            LucideIcons.arrowUpRight,
            AppColors.error,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, double amount, IconData icon, Color color) {
    return StatTile(
      label: label,
      value: CurrencyService().formatAmountCompact(amount),
      icon: icon,
      accentColor: color,
      radius: AppTheme.cardRadius,
      bordered: true,
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return AppSectionHeader(
      title: title,
      subtitle: subtitle,
    );
  }

  Widget _buildSmartInsightsSection(AnalyticsState state) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader(
                'Flux Intelligence', 'Smart analysis of your habits'),
            Icon(LucideIcons.sparkles, color: AppColors.primary, size: 24),
          ],
        ),
        const SizedBox(height: 16),
        if (state is SpendingAnalysisLoaded)
          _buildBulkInsightCard(
            (state.analysis['insights'] as List).cast<String>(),
            colorScheme,
          )
        else
          _buildInsightSkeleton(),
      ],
    );
  }

  Widget _buildRecommendationsSection(Map<String, dynamic>? analysis) {
    final recommendations =
        (analysis?['recommendations'] as List<dynamic>? ?? []).cast<String>();
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
            'Flux Recommendations', 'Actionable steps to improve'),
        const SizedBox(height: 16),
        if (recommendations.isNotEmpty)
          _buildBulkInsightCard(recommendations, colorScheme,
              icon: LucideIcons.lightbulb, iconColor: Colors.amber)
        else
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: AppTheme.surfaceDecoration(context),
            child: const Text(
                'Add more transactions to receive smart recommendations.'),
          ),
      ],
    );
  }

  // One card holding every item with a divider between rows, instead of a
  // separately-bordered/margined card per item - same grouping used for
  // the transactions list and the dashboard's Smart Insights card.
  Widget _buildBulkInsightCard(
    List<String> items,
    ColorScheme colorScheme, {
    IconData? icon,
    Color? iconColor,
  }) {
    return Container(
      decoration: AppTheme.tintedSurfaceDecoration(
        context,
        tint: AppColors.primary,
        radius: 20,
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                color: AppColors.primary.withValues(alpha: 0.10),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: iconColor ?? AppColors.primary),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      items[i],
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(ColorScheme colorScheme) {
    return PopupMenuButton<TimelineFilter>(
      initialValue: _timelineFilter,
      onSelected: (filter) {
        if (filter == TimelineFilter.custom) {
          _pickCustomRange();
        } else {
          setState(() => _timelineFilter = filter);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.cardSurface(context),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: colorScheme.outline.withValues(alpha: 0.10)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _timelineFilter == TimelineFilter.lastWeek
                  ? 'Last Week'
                  : _timelineFilter == TimelineFilter.lastMonth
                      ? 'Last Month'
                      : _timelineFilter == TimelineFilter.last3Months
                          ? 'Last 3 Months'
                          : 'Custom',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              LucideIcons.chevronDown,
              size: 20,
              color: colorScheme.onSurface,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: TimelineFilter.lastWeek,
          child: Text('Last Week'),
        ),
        const PopupMenuItem(
          value: TimelineFilter.lastMonth,
          child: Text('Last Month'),
        ),
        const PopupMenuItem(
          value: TimelineFilter.last3Months,
          child: Text('Last 3 Months'),
        ),
        const PopupMenuItem(
          value: TimelineFilter.custom,
          child: Text('Custom Range'),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildInsightSkeleton() {
    return Column(
      children: List.generate(
          2,
          (index) => Container(
                height: 80,
                margin: const EdgeInsets.only(bottom: 12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.cardSurface(context),
                  borderRadius: BorderRadius.circular(20),
                ),
              )),
    );
  }

  Widget _buildEmptyState() {
    return const EmptyStateView(
      icon: LucideIcons.barChart3,
      iconColor: AppColors.textTertiary,
      title: 'No financial data found',
      subtitle: 'Start adding transactions to see analysis',
    );
  }
}
