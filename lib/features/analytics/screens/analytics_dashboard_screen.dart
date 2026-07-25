import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/services/currency_service.dart';
import '../../auth/auth_bloc.dart';
import '../../transaction/transaction_bloc.dart';
import '../analytics_bloc.dart';
import '../widgets/category_breakdown_chart.dart';
import '../widgets/insights_card.dart';
import '../widgets/trend_analysis_chart.dart';
import '../widgets/weekly_spending_chart.dart';
import '../../../core/utils/date_range_filter.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  TimelineFilter _timelineFilter = TimelineFilter.lastMonth;
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
  }

  DateTimeRange _getActiveRange() =>
      activeRangeFor(_timelineFilter, customRange: _customRange);

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: _customRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
      builder: (context, child) => Theme(
        data: Theme.of(context),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _customRange = picked;
        _timelineFilter = TimelineFilter.custom;
      });
    }
  }

  List<Transaction> _filterTransactions(List<Transaction> transactions) {
    final range = _getActiveRange();
    return transactions.where((t) {
      return !t.date.isBefore(range.start) && !t.date.isAfter(range.end);
    }).toList();
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
              final transactions = _filterTransactions(transactionState.transactions);

              return BlocBuilder<AnalyticsBloc, AnalyticsState>(
                builder: (context, analyticsState) {
                  final analysis = analyticsState is SpendingAnalysisLoaded ? analyticsState.analysis : null;
                  
                  return RefreshIndicator(
                    onRefresh: () async {
                       final user = context.read<AuthBloc>().state;
                       if (user is AuthAuthenticated) {
                         context.read<TransactionBloc>().add(LoadTransactions(user.user.id));
                       }
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHealthScoreSection(analysis),
                          const SizedBox(height: 24),
                          _buildQuickStats(transactions),
                          const SizedBox(height: 24),
                          _buildEfficiencySection(analysis),
                          const SizedBox(height: 24),
                          _buildSmartInsightsSection(analyticsState),
                          const SizedBox(height: 24),
                          _buildSubscriptionsSection(analysis),
                          const SizedBox(height: 24),
                          _buildSectionHeader('Spending Trend', 'Your weekly expense activity'),
                          const SizedBox(height: 16),
                          WeeklySpendingChart(transactions: transactions),
                          const SizedBox(height: 24),
                          _buildWealthProjectionSection(analysis),
                          const SizedBox(height: 24),
                          _buildSectionHeader('Monthly Comparison', 'Income vs Expenses'),
                          const SizedBox(height: 16),
                          TrendAnalysisChart(transactions: transactions),
                          const SizedBox(height: 24),
                          _buildSectionHeader('Category Breakdown', 'Where your money goes'),
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

  Widget _buildHealthScoreSection(Map<String, dynamic>? analysis) {
    final score = analysis?['healthScore'] ?? 0;
    final color = score > 80 ? AppColors.success : (score > 50 ? Colors.orange : AppColors.error);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final cardBorderColor = isDark
      ? colorScheme.outline.withOpacity(0.45)
      : color.withOpacity(0.2);
    final progressTrackColor = isDark
      ? colorScheme.outline.withOpacity(0.25)
      : color.withOpacity(0.1);

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
                    fontWeight: FontWeight.w700,
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
                  'Based on your savings rate, stability, and spending efficiency.',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getHealthStatus(int score) {
    if (score > 80) return 'Excellent habits!';
    if (score > 60) return 'Solid foundation';
    if (score > 40) return 'Needs attention';
    return 'Critical review needed';
  }

  Widget _buildEfficiencySection(Map<String, dynamic>? analysis) {
    final efficiency = analysis?['efficiency'] as Map<String, dynamic>? ?? {'needs': 0.0, 'wants': 0.0, 'savings': 0.0};
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Spending Efficiency', 'Adherence to the 50/30/20 rule'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.surfaceDecoration(context),
          child: Column(
            children: [
              _buildEfficiencyRow('Needs (Fixed)', efficiency['needs'], 50, AppColors.primary),
              const SizedBox(height: 16),
              _buildEfficiencyRow('Wants (Lifestyle)', efficiency['wants'], 30, Colors.orange),
              const SizedBox(height: 16),
              _buildEfficiencyRow('Savings (Wealth)', efficiency['savings'], 20, AppColors.success),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEfficiencyRow(String label, dynamic value, double target, Color color) {
    final double val = (value as num).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            Text('${val.toStringAsFixed(1)}% / $target%', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: val / 100,
            backgroundColor: color.withOpacity(0.1),
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
        _buildSectionHeader('Detected Subscriptions', 'Recurring monthly payments identified'),
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
                    color: Theme.of(context).colorScheme.outline.withOpacity(
                      isDark ? 0.14 : 0.08,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.10 : 0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sub['title'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const Spacer(),
                    Text(
                      CurrencyService().formatAmount(sub['amount'] as double),
                      style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      sub['category'],
                      style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
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
        tint: Colors.indigo,
        radius: 32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.rocket_launch_rounded, color: Theme.of(context).colorScheme.onSurface, size: 32),
          const SizedBox(height: 16),
          Text(
            'Wealth Projection',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep up your current habits, and you\'ll have an extra ${CurrencyService().formatAmount(projected)} in 6 months.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.72), fontSize: 14),
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
        color: AppTheme.cardSurface(context).withOpacity(0.78),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.trending_up, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text(
            'Trajectory: High Growth',
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
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
            Icons.south_west_rounded,
            AppColors.success,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Expenses', 
            expenses, 
            Icons.north_east_rounded,
            AppColors.error,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, double amount, IconData icon, Color color) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.surfaceDecoration(context, radius: 24).copyWith(
        border: Border.all(
          color: isDark ? color.withOpacity(0.12) : colorScheme.outline.withOpacity(0.10),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface.withOpacity(0.65),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyService().formatAmount(amount).replaceAll('.00', ''),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.sectionTitleStyle(context).copyWith(fontSize: 20),
        ),
        Text(
          subtitle,
          style: AppTheme.sectionSubtitleStyle(context),
        ),
      ],
    );
  }

  Widget _buildSmartInsightsSection(AnalyticsState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader('Flux Intelligence', 'Smart analysis of your habits'),
            Icon(Icons.auto_awesome, color: AppColors.primary, size: 24),
          ],
        ),
        const SizedBox(height: 16),
        if (state is SpendingAnalysisLoaded)
          ...state.analysis['insights'].map<Widget>((insight) {
            return InsightsCard(
              title: 'Pattern Detected',
              description: insight,
              icon: Icons.analytics_rounded,
              color: AppColors.primary,
            );
          }).toList()
        else
          _buildInsightSkeleton(),
      ],
    );
  }

  Widget _buildRecommendationsSection(Map<String, dynamic>? analysis) {
    final recommendations = analysis?['recommendations'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Flux Recommendations', 'Actionable steps to improve'),
        const SizedBox(height: 16),
        if (recommendations.isNotEmpty)
          ...recommendations.map((rec) => InsightsCard(
            title: 'Recommendation',
            description: rec.toString(),
            icon: Icons.lightbulb_outline_rounded,
            color: Colors.amber,
            isTip: true,
          )).toList()
        else
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: AppTheme.surfaceDecoration(context),
            child: const Text('Add more transactions to receive smart recommendations.'),
          ),
      ],
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
          border: Border.all(color: colorScheme.outline.withOpacity(0.10)),
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
              Icons.keyboard_arrow_down_rounded,
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
      children: List.generate(2, (index) => Container(
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          const Text('No financial data found'),
          const SizedBox(height: 8),
          const Text('Start adding transactions to see analysis'),
        ],
      ),
    );
  }
}
