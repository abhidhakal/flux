import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/models/income_model.dart';
import '../../../core/services/currency_service.dart';
import '../../../shared/widgets/skeleton_components.dart';
import '../../auth/auth_bloc.dart';
import '../../transaction/transaction_bloc.dart';
import '../../income/income_bloc.dart';
import '../analytics_bloc.dart';
import '../widgets/spending_chart.dart';
import '../widgets/category_breakdown_chart.dart';
import '../widgets/insights_card.dart';
import '../widgets/trend_analysis_chart.dart';
import '../widgets/weekly_spending_chart.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  String _selectedPeriod = 'This Month';
  final List<String> _periods = ['This Month', 'Last 3 Months', 'This Year'];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthBloc>().state;
    if (user is AuthAuthenticated) {
      context.read<TransactionBloc>().add(LoadTransactions(user.user.id));
      context.read<IncomeBloc>().add(LoadIncome(user.user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Insights'),
        centerTitle: false,
        backgroundColor: colorScheme.background,
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
                final incomeState = context.read<IncomeBloc>().state;
                if (incomeState is IncomeLoaded) {
                  context.read<AnalyticsBloc>().add(
                    AnalyzeSpendingPatterns(state.transactions, incomeState.incomes),
                  );
                }
              }
            },
          ),
          BlocListener<IncomeBloc, IncomeState>(
            listener: (context, state) {
              if (state is IncomeLoaded) {
                final transState = context.read<TransactionBloc>().state;
                if (transState is TransactionLoaded) {
                  context.read<AnalyticsBloc>().add(
                    AnalyzeSpendingPatterns(transState.transactions, state.incomes),
                  );
                }
              }
            },
          ),
        ],
        child: BlocBuilder<TransactionBloc, TransactionState>(
          builder: (context, transactionState) {
            return BlocBuilder<IncomeBloc, IncomeState>(
              builder: (context, incomeState) {
                if (transactionState is TransactionLoading || incomeState is IncomeLoading) {
                  return _buildLoadingState();
                }

                if (transactionState is TransactionLoaded && incomeState is IncomeLoaded) {
                  return BlocBuilder<AnalyticsBloc, AnalyticsState>(
                    builder: (context, analyticsState) {
                      final analysis = analyticsState is SpendingAnalysisLoaded ? analyticsState.analysis : null;
                      
                      return RefreshIndicator(
                        onRefresh: () async {
                           final user = context.read<AuthBloc>().state;
                           if (user is AuthAuthenticated) {
                             context.read<TransactionBloc>().add(LoadTransactions(user.user.id));
                             context.read<IncomeBloc>().add(LoadIncome(user.user.id));
                           }
                        },
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 120),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Financial Health Score (Premium Highlight)
                              _buildHealthScoreSection(analysis),
                              
                              const SizedBox(height: 32),
                              
                              // 2. Quick Stats Row
                              _buildQuickStats(transactionState.transactions, incomeState.incomes),
                              
                              const SizedBox(height: 32),

                              // 3. Budget Efficiency (50/30/20 Rule)
                              _buildEfficiencySection(analysis),

                              const SizedBox(height: 32),
                              
                              // 4. AI Insights Section
                              _buildInsightsSection(analyticsState),

                              const SizedBox(height: 32),

                              // 5. Detected Subscriptions
                              _buildSubscriptionsSection(analysis),

                              const SizedBox(height: 32),

                              // Main Spending Chart
                              _buildSectionHeader('Spending Trend', 'Your weekly expense activity'),
                              const SizedBox(height: 16),
                              WeeklySpendingChart(transactions: transactionState.transactions),

                              const SizedBox(height: 32),

                              // 6. Projected Wealth
                              _buildWealthProjectionSection(analysis),

                              const SizedBox(height: 32),

                              // Monthly Comparison Chart
                              _buildSectionHeader('Monthly Comparison', 'Income vs Expenses'),
                              const SizedBox(height: 16),
                              TrendAnalysisChart(
                                transactions: transactionState.transactions,
                                incomes: incomeState.incomes,
                              ),

                              const SizedBox(height: 32),

                              // Category Breakdown Section
                              _buildSectionHeader('Category Breakdown', 'Where your money goes'),
                              const SizedBox(height: 16),
                              CategoryBreakdownChart(transactions: transactionState.transactions),
                              
                              const SizedBox(height: 32),
                              
                              // Recommendations Section
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildHealthScoreSection(Map<String, dynamic>? analysis) {
    final score = analysis?['healthScore'] ?? 0;
    final color = score > 80 ? AppColors.success : (score > 50 ? Colors.orange : AppColors.error);
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: color.withOpacity(0.2)),
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
                  backgroundColor: color.withOpacity(0.1),
                  color: color,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
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
                    fontWeight: FontWeight.bold,
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
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
          ),
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
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade700, Colors.indigo.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 32),
          const SizedBox(height: 16),
          const Text(
            'Wealth Projection',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep up your current habits, and you\'ll have an extra ${CurrencyService().formatAmount(projected)} in 6 months.',
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
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
        color: Colors.white.withOpacity(0.1),
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

  Widget _buildQuickStats(List<Transaction> transactions, List<Income> incomes) {
    final expenses = transactions.where((t) => t.isExpense).fold(0.0, (sum, t) => sum + t.amount);
    final totalIncome = incomes.fold(0.0, (sum, i) => sum + i.amount);

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyService().formatAmount(amount).replaceAll('.00', ''),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
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
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsSection(AnalyticsState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader('AI Intelligence', 'Smart analysis of your habits'),
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
        _buildSectionHeader('Smart Recommendations', 'Actionable steps to improve'),
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
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
            ),
            child: const Text('Add more transactions to receive smart recommendations.'),
          ),
      ],
    );
  }

  Widget _buildPeriodSelector(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPeriod,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() => _selectedPeriod = newValue);
            }
          },
          items: _periods.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
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
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
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
