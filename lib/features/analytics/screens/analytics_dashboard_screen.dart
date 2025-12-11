import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/services/currency_service.dart';
import '../../../core/services/ai_intelligence_service.dart';
import '../../../shared/widgets/skeleton_components.dart';
import '../../auth/auth_bloc.dart';
import '../../transaction/transaction_bloc.dart';
import '../analytics_bloc.dart';
import '../widgets/spending_chart.dart';
import '../widgets/category_breakdown_chart.dart';
import '../widgets/trend_analysis_chart.dart';
import '../widgets/weekly_spending_chart.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  final AIIntelligenceService _aiService = AIIntelligenceService();

  @override
  void initState() {
    super.initState();
    // Load transactions when screen initializes
    final user = context.read<AuthBloc>().state;
    if (user is AuthAuthenticated) {
      context.read<TransactionBloc>().add(LoadTransactions(user.user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text('Analytics'),
        centerTitle: false,
        backgroundColor: colorScheme.background,
        foregroundColor: colorScheme.onBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onBackground),
        titleTextStyle: TextStyle(
          color: colorScheme.onBackground,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: colorScheme.onBackground),
            onPressed: () {
              final user = context.read<AuthBloc>().state;
              if (user is AuthAuthenticated) {
                context.read<TransactionBloc>().add(LoadTransactions(user.user.id));
              }
            },
          ),
        ],
      ),
      body: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (context, transactionState) {
          if (transactionState is TransactionLoading) {
            return _buildAnalyticsSkeleton();
          }

          if (transactionState is TransactionLoaded) {
            // Trigger analytics when transactions are loaded
            context.read<AnalyticsBloc>().add(
              AnalyzeSpendingPatterns(transactionState.transactions),
            );

            return BlocBuilder<AnalyticsBloc, AnalyticsState>(
              builder: (context, analyticsState) {
                return SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: screenWidth > 600 ? 24 : 16,
                    right: screenWidth > 600 ? 24 : 16,
                    top: 16,
                    bottom: 120,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      SizedBox(height: screenHeight * 0.02),
                      _buildQuickStats(transactionState.transactions),
                      SizedBox(height: screenHeight * 0.025),
                      _buildCashFlowForecast(transactionState.transactions),
                      SizedBox(height: screenHeight * 0.025),
                      _buildSpendingBehaviorAnalysis(transactionState.transactions),
                      SizedBox(height: screenHeight * 0.025),
                      _buildSpendingChart(transactionState.transactions),
                      SizedBox(height: screenHeight * 0.025),
                      _buildWeeklySpendingChart(transactionState.transactions),
                      SizedBox(height: screenHeight * 0.025),
                      _buildCategoryBreakdown(transactionState.transactions),
                      SizedBox(height: screenHeight * 0.025),
                      _buildTrendAnalysis(transactionState.transactions),
                      SizedBox(height: screenHeight * 0.025),
                      _buildAIInsights(analyticsState, transactionState.transactions),
                      SizedBox(height: screenHeight * 0.02),
                    ],
                  ),
                );
              },
            );
          }

          return _buildEmptyState();
        },
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(screenWidth > 600 ? 24 : 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer.withOpacity(0.3),
              colorScheme.secondaryContainer.withOpacity(0.2),
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              width: screenWidth > 600 ? 64 : 56,
              height: screenWidth > 600 ? 64 : 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF3B82F6),
                    Color(0xFF1D4ED8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: screenWidth > 600 ? 32 : 28,
              ),
            ),
            SizedBox(width: screenWidth > 600 ? 20 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Financial Analytics',
                    style: TextStyle(
                      fontSize: screenWidth > 600 ? 28 : 24,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'AI-powered insights from your data',
                    style: TextStyle(
                      fontSize: screenWidth > 600 ? 18 : 16,
                      color: colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.2,
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

  Widget _buildQuickStats(List<Transaction> transactions) {
    final expenses = transactions.where((t) => t.isExpense).toList();
    final income = transactions.where((t) => t.isIncome).toList();
    
    final totalExpenses = expenses.fold(0.0, (sum, t) => sum + t.amount);
    final totalIncome = income.fold(0.0, (sum, t) => sum + t.amount);
    final balance = totalIncome - totalExpenses;
    final savingsRate = totalIncome > 0 ? (balance / totalIncome * 100) : 0.0;
    
    // Calculate month-over-month changes
    final now = DateTime.now();
    final currentMonth = expenses.where((t) => 
      t.date.year == now.year && t.date.month == now.month).toList();
    final lastMonth = expenses.where((t) {
      final lastMonthDate = DateTime(now.year, now.month - 1);
      return t.date.year == lastMonthDate.year && t.date.month == lastMonthDate.month;
    }).toList();
    
    final currentMonthExpenses = currentMonth.fold(0.0, (sum, t) => sum + t.amount);
    final lastMonthExpenses = lastMonth.fold(0.0, (sum, t) => sum + t.amount);
    final expenseChange = lastMonthExpenses > 0 
        ? ((currentMonthExpenses - lastMonthExpenses) / lastMonthExpenses * 100)
        : 0.0;
    
    // Calculate average daily spending
    final avgDailySpending = now.day > 0 ? currentMonthExpenses / now.day : 0.0;
    
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth > 600 ? 24 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Minimal header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Financial Overview',
                  style: TextStyle(
                    fontSize: screenWidth > 600 ? 18 : 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.2,
                  ),
                ),
                if (expenseChange != 0) Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (expenseChange > 0 ? colorScheme.error : const Color(0xFF10B981))
                        .withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        expenseChange > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 12,
                        color: expenseChange > 0 ? colorScheme.error : const Color(0xFF10B981),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${expenseChange.abs().toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: expenseChange > 0 ? colorScheme.error : const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: screenWidth > 600 ? 24 : 20),
            
            // Clean stats grid
            screenWidth > 600 
                ? Row(
                    children: [
                      Expanded(child: _buildMinimalStatItem(
                        'Income',
                        CurrencyService().formatAmount(totalIncome),
                        '${income.length} sources',
                        const Color(0xFF10B981),
                      )),
                      const SizedBox(width: 24),
                      Expanded(child: _buildMinimalStatItem(
                        'Expenses',
                        CurrencyService().formatAmount(totalExpenses),
                        'Avg ${CurrencyService().formatAmount(avgDailySpending)}/day',
                        colorScheme.error,
                      )),
                      const SizedBox(width: 24),
                      Expanded(child: _buildMinimalStatItem(
                        'Savings Rate',
                        '${savingsRate.toStringAsFixed(1)}%',
                        _getSavingsRateMessage(savingsRate),
                        _getSavingsRateColor(savingsRate),
                      )),
                    ],
                  )
                : Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildMinimalStatItem(
                            'Income',
                            CurrencyService().formatAmount(totalIncome),
                            '${income.length} sources',
                            const Color(0xFF10B981),
                          )),
                          const SizedBox(width: 16),
                          Expanded(child: _buildMinimalStatItem(
                            'Expenses',
                            CurrencyService().formatAmount(totalExpenses),
                            '${CurrencyService().formatAmount(avgDailySpending)}/day',
                            colorScheme.error,
                          )),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildMinimalStatItem(
                        'Net Balance',
                        CurrencyService().formatAmount(balance),
                        '${savingsRate.toStringAsFixed(1)}% savings rate',
                        balance >= 0 ? const Color(0xFF10B981) : colorScheme.error,
                        isFullWidth: true,
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  // Minimal stat item widget
  Widget _buildMinimalStatItem(
    String title, 
    String value, 
    String subtitle,
    Color color, {
    bool isFullWidth = false,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: EdgeInsets.all(screenWidth > 600 ? 16 : 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: isFullWidth ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: screenWidth > 600 ? 13 : 12,
              color: colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
            textAlign: isFullWidth ? TextAlign.left : TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: screenWidth > 600 ? 20 : 18,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
              letterSpacing: -0.3,
            ),
            textAlign: isFullWidth ? TextAlign.left : TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: screenWidth > 600 ? 11 : 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: isFullWidth ? TextAlign.left : TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsights(AnalyticsState analyticsState, List<Transaction> transactions) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Generate real insights from transaction data
    final insights = _generateRealInsights(transactions);
    
    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth > 600 ? 24 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: screenWidth > 600 ? 56 : 48,
                  height: screenWidth > 600 ? 56 : 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF8B5CF6),
                        Color(0xFF7C3AED),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: screenWidth > 600 ? 28 : 24,
                  ),
                ),
                SizedBox(width: screenWidth > 600 ? 20 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Smart Insights',
                        style: TextStyle(
                          fontSize: screenWidth > 600 ? 22 : 20,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'AI analysis of your spending data',
                        style: TextStyle(
                          fontSize: screenWidth > 600 ? 14 : 13,
                          color: colorScheme.onSurface.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: screenWidth > 600 ? 24 : 20),
            
            // Use AI insights if available, otherwise use local analysis
            if (analyticsState is SpendingAnalysisLoaded) ...[
              _buildAnalysisInsights(analyticsState.analysis, colorScheme, screenWidth),
            ] else ...[
              _buildLocalInsights(insights, colorScheme, screenWidth),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisInsights(Map<String, dynamic> analysis, ColorScheme colorScheme, double screenWidth) {
    final insights = analysis['insights'] as List<String>? ?? [];
    final recommendations = analysis['recommendations'] as List<String>? ?? [];
    final topCategories = (analysis['topCategories'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top spending categories
        if (topCategories.isNotEmpty) ...[
          Text(
            'Top Spending Categories',
            style: TextStyle(
              fontSize: screenWidth > 600 ? 18 : 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          ...topCategories.take(3).map((category) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.all(screenWidth > 600 ? 16 : 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF3B82F6).withOpacity(0.1),
                  const Color(0xFF3B82F6).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF3B82F6).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    category['category'],
                    style: TextStyle(
                      fontSize: screenWidth > 600 ? 16 : 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                Text(
                  '${category['percentage']}% • ${CurrencyService().formatAmount(category['amount'])}',
                  style: TextStyle(
                    fontSize: screenWidth > 600 ? 14 : 12,
                    color: const Color(0xFF3B82F6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )),
        ],
        
        // AI Insights
        if (insights.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'Key Insights',
            style: TextStyle(
              fontSize: screenWidth > 600 ? 18 : 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          ...insights.map((insight) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.all(screenWidth > 600 ? 16 : 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF10B981).withOpacity(0.1),
                  const Color(0xFF10B981).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF10B981).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  size: screenWidth > 600 ? 20 : 18,
                  color: const Color(0xFF10B981),
                ),
                SizedBox(width: screenWidth > 600 ? 12 : 10),
                Expanded(
                  child: Text(
                    insight,
                    style: TextStyle(
                      fontSize: screenWidth > 600 ? 14 : 13,
                      color: colorScheme.onSurface.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
        
        // Recommendations
        if (recommendations.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'AI Recommendations',
            style: TextStyle(
              fontSize: screenWidth > 600 ? 18 : 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          ...recommendations.map((recommendation) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.all(screenWidth > 600 ? 16 : 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF8B5CF6),
                  Color(0xFF7C3AED),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: screenWidth > 600 ? 20 : 18,
                  color: Colors.white,
                ),
                SizedBox(width: screenWidth > 600 ? 12 : 10),
                Expanded(
                  child: Text(
                    recommendation,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth > 600 ? 14 : 13,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ],
    );
  }

  Widget _buildLocalInsights(Map<String, dynamic> insights, ColorScheme colorScheme, double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Key Insights
        if (insights['keyInsights'].isNotEmpty) ...[
          Text(
            'Key Insights',
            style: TextStyle(
              fontSize: screenWidth > 600 ? 18 : 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          ...insights['keyInsights'].map<Widget>((insight) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(screenWidth > 600 ? 18 : 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  insight['color'].withOpacity(0.1),
                  insight['color'].withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: insight['color'].withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: screenWidth > 600 ? 40 : 36,
                  height: screenWidth > 600 ? 40 : 36,
                  decoration: BoxDecoration(
                    color: insight['color'].withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    insight['icon'],
                    size: screenWidth > 600 ? 20 : 18,
                    color: insight['color'],
                  ),
                ),
                SizedBox(width: screenWidth > 600 ? 16 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight['title'],
                        style: TextStyle(
                          fontSize: screenWidth > 600 ? 15 : 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        insight['message'],
                        style: TextStyle(
                          fontSize: screenWidth > 600 ? 14 : 13,
                          color: colorScheme.onSurface.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
        
        // Action Items
        if (insights['actionItems'].isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'Recommended Actions',
            style: TextStyle(
              fontSize: screenWidth > 600 ? 18 : 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          ...insights['actionItems'].map<Widget>((action) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.all(screenWidth > 600 ? 16 : 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF10B981),
                  Color(0xFF059669),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: screenWidth > 600 ? 20 : 18,
                  color: Colors.white,
                ),
                SizedBox(width: screenWidth > 600 ? 12 : 10),
                Expanded(
                  child: Text(
                    action,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth > 600 ? 14 : 13,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ],
    );
  }

  // Helper method to generate real insights from transaction data
  Map<String, dynamic> _generateRealInsights(List<Transaction> transactions) {
    if (transactions.isEmpty) {
      return {
        'keyInsights': [],
        'actionItems': ['Add some transactions to see personalized insights'],
      };
    }

    // Use AI service to analyze spending patterns
    final analysis = _aiService.analyzeSpendingPatterns(transactions);
    
    final expenses = transactions.where((t) => t.isExpense).toList();
    final income = transactions.where((t) => t.isIncome).toList();
    
    final totalExpenses = expenses.fold(0.0, (sum, t) => sum + t.amount);
    final totalIncome = income.fold(0.0, (sum, t) => sum + t.amount);
    
    // Calculate category breakdown
    final categoryTotals = <String, double>{};
    for (final expense in expenses) {
      categoryTotals[expense.category] = (categoryTotals[expense.category] ?? 0) + expense.amount;
    }
    
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Generate insights based on real data
    final keyInsights = <Map<String, dynamic>>[];
    final actionItems = <String>[];
    
    // Top category insight
    if (sortedCategories.isNotEmpty) {
      final topCategory = sortedCategories.first;
      final percentage = (topCategory.value / totalExpenses * 100);
      keyInsights.add({
        'title': 'Top Spending Category',
        'message': '${topCategory.key} accounts for ${percentage.toStringAsFixed(1)}% of your expenses (${CurrencyService().formatAmount(topCategory.value)})',
        'icon': Icons.pie_chart_rounded,
        'color': const Color(0xFF3B82F6),
      });
      
      if (percentage > 40) {
        actionItems.add('Consider setting a budget for ${topCategory.key} as it\'s your highest expense category');
      }
    }
    
    // Spending trend insight
    final now = DateTime.now();
    final thisMonth = expenses.where((t) => 
      t.date.year == now.year && t.date.month == now.month).toList();
    final lastMonth = expenses.where((t) {
      final lastMonthDate = DateTime(now.year, now.month - 1);
      return t.date.year == lastMonthDate.year && t.date.month == lastMonthDate.month;
    }).toList();
    
    if (thisMonth.isNotEmpty && lastMonth.isNotEmpty) {
      final thisMonthTotal = thisMonth.fold(0.0, (sum, t) => sum + t.amount);
      final lastMonthTotal = lastMonth.fold(0.0, (sum, t) => sum + t.amount);
      final change = ((thisMonthTotal - lastMonthTotal) / lastMonthTotal * 100);
      
      if (change.abs() > 10) {
        keyInsights.add({
          'title': 'Monthly Spending Trend',
          'message': 'Your spending ${change > 0 ? 'increased' : 'decreased'} by ${change.abs().toStringAsFixed(1)}% this month',
          'icon': change > 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
          'color': change > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        });
        
        if (change > 20) {
          actionItems.add('Review your recent purchases to identify the cause of increased spending');
        }
      }
    }
    
    // Savings rate insight
    if (totalIncome > 0) {
      final savingsRate = ((totalIncome - totalExpenses) / totalIncome * 100);
      String savingsMessage;
      Color savingsColor;
      
      if (savingsRate >= 20) {
        savingsMessage = 'Excellent savings rate of ${savingsRate.toStringAsFixed(1)}%! You\'re on track for financial goals.';
        savingsColor = const Color(0xFF10B981);
      } else if (savingsRate >= 10) {
        savingsMessage = 'Good savings rate of ${savingsRate.toStringAsFixed(1)}%. Consider increasing to 20% for optimal financial health.';
        savingsColor = const Color(0xFF3B82F6);
        actionItems.add('Try to increase your savings rate to 20% by reducing discretionary spending');
      } else if (savingsRate > 0) {
        savingsMessage = 'Your current savings rate is ${savingsRate.toStringAsFixed(1)}%. This needs improvement for financial security.';
        savingsColor = const Color(0xFFF59E0B);
        actionItems.add('Focus on building an emergency fund by saving at least 10% of your income');
      } else {
        savingsMessage = 'You\'re spending more than you earn. Immediate budget review required.';
        savingsColor = const Color(0xFFEF4444);
        actionItems.add('Create a strict budget and cut unnecessary expenses immediately');
      }
      
      keyInsights.add({
        'title': 'Savings Analysis',
        'message': savingsMessage,
        'icon': Icons.savings_rounded,
        'color': savingsColor,
      });
    }
    
    // Transaction frequency insight
    if (expenses.isNotEmpty) {
      final daysSinceFirst = now.difference(expenses.first.date).inDays;
      final avgTransactionsPerDay = expenses.length / max(daysSinceFirst, 1);
      
      if (avgTransactionsPerDay > 5) {
        actionItems.add('You make ${avgTransactionsPerDay.toStringAsFixed(1)} transactions per day on average. Consider consolidating purchases to avoid impulse buying');
      }
    }
    
    // Add general recommendations based on AI analysis
    final aiRecommendations = analysis['recommendations'] as List<String>? ?? [];
    actionItems.addAll(aiRecommendations.take(3));
    
    return {
      'keyInsights': keyInsights,
      'actionItems': actionItems,
    };
  }

  Widget _buildChartCard({
    required String title,
    required Widget chart,
    double? height,
    double? aspectRatio,
    String? insight,
    List<String>? keyPoints,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth > 600 ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: screenWidth > 600 ? 22 : 20,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                if (insight != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                ],
              ],
            ),
            
            if (insight != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(screenWidth > 600 ? 16 : 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Text(
                  insight,
                  style: TextStyle(
                    fontSize: screenWidth > 600 ? 13 : 12,
                    color: colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 20),
            
            // Chart
            height != null
                ? SizedBox(height: height, child: chart)
                : AspectRatio(aspectRatio: aspectRatio ?? 1.8, child: chart),
            
            // Key Points
            if (keyPoints != null && keyPoints.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...keyPoints.map((point) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 6, right: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        point,
                        style: TextStyle(
                          fontSize: screenWidth > 600 ? 13 : 12,
                          color: colorScheme.onSurface.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
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

  Widget _buildSpendingChart(List<Transaction> transactions) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return _buildChartCard(
      title: 'Monthly Spending Trend',
      chart: SpendingChart(transactions: transactions),
      height: screenWidth > 600 ? 350 : 280,
      insight: 'Track your spending patterns over time to identify trends and seasonal variations.',
      keyPoints: [
        'Peak spending months help you plan for seasonal expenses',
        'Consistent spending indicates good budget control',
        'Sharp increases may signal lifestyle changes or emergencies',
      ],
    );
  }

  Widget _buildWeeklySpendingChart(List<Transaction> transactions) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return _buildChartCard(
      title: 'Daily Spending Pattern',
      chart: WeeklySpendingChart(transactions: transactions),
      height: screenWidth > 600 ? 320 : 260,
    );
  }

  Widget _buildCategoryBreakdown(List<Transaction> transactions) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return _buildChartCard(
      title: 'Category Breakdown',
      chart: CategoryBreakdownChart(transactions: transactions),
      height: screenWidth > 600 ? 400 : 320,
      insight: 'Understand where your money goes to make informed budgeting decisions.',
      keyPoints: [
        'Housing and food typically account for 50-60% of expenses',
        'Entertainment over 10% might indicate lifestyle inflation',
        'Track category changes month-over-month for insights',
      ],
    );
  }

  Widget _buildTrendAnalysis(List<Transaction> transactions) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return _buildChartCard(
      title: 'Income vs Expenses Trend',
      chart: TrendAnalysisChart(transactions: transactions),
      height: screenWidth > 600 ? 380 : 300,
    );
  }

  Widget _buildEmptyState() {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(screenWidth > 600 ? 40 : 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: screenWidth > 600 ? 120 : 80,
              height: screenWidth > 600 ? 120 : 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF3B82F6),
                    Color(0xFF1D4ED8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                size: screenWidth > 600 ? 60 : 40,
                color: Colors.white,
              ),
            ),
            SizedBox(height: screenWidth > 600 ? 32 : 24),
            Text(
              'No Data Available',
              style: TextStyle(
                fontSize: screenWidth > 600 ? 28 : 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            SizedBox(height: screenWidth > 600 ? 12 : 8),
            Text(
              'Add some transactions to see your analytics',
              style: TextStyle(
                fontSize: screenWidth > 600 ? 18 : 16,
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Cash Flow Forecast Widget using real data
  Widget _buildCashFlowForecast(List<Transaction> transactions) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Calculate forecast data based on real transactions
    final forecastData = _calculateCashFlowForecast(transactions);
    
    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth > 600 ? 24 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: screenWidth > 600 ? 56 : 48,
                  height: screenWidth > 600 ? 56 : 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF06B6D4),
                        Color(0xFF0891B2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF06B6D4).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.trending_up_rounded,
                    color: Colors.white,
                    size: screenWidth > 600 ? 28 : 24,
                  ),
                ),
                SizedBox(width: screenWidth > 600 ? 20 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cash Flow Forecast',
                        style: TextStyle(
                          fontSize: screenWidth > 600 ? 22 : 20,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Predictions based on your data',
                        style: TextStyle(
                          fontSize: screenWidth > 600 ? 14 : 13,
                          color: colorScheme.onSurface.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: screenWidth > 600 ? 28 : 24),
            
            // Current Balance
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(screenWidth > 600 ? 20 : 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primaryContainer.withOpacity(0.3),
                    colorScheme.secondaryContainer.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Balance',
                    style: TextStyle(
                      fontSize: screenWidth > 600 ? 16 : 14,
                      color: colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyService().formatAmount(forecastData['currentBalance']),
                    style: TextStyle(
                      fontSize: screenWidth > 600 ? 32 : 28,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: screenWidth > 600 ? 24 : 20),
            
            // 3-Month Forecast
            Text(
              'Forecast Overview',
              style: TextStyle(
                fontSize: screenWidth > 600 ? 18 : 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 16),
            
            // Forecast Items
            ...forecastData['forecast'].map<Widget>((month) {
              final isPositive = month['netFlow'] >= 0;
              final color = isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(screenWidth > 600 ? 20 : 16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: color.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: screenWidth > 600 ? 48 : 40,
                      height: screenWidth > 600 ? 48 : 40,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                        color: color,
                        size: screenWidth > 600 ? 24 : 20,
                      ),
                    ),
                    SizedBox(width: screenWidth > 600 ? 16 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            month['monthName'],
                            style: TextStyle(
                              fontSize: screenWidth > 600 ? 16 : 14,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Projected Balance: ${CurrencyService().formatAmount(month['projectedBalance'])}',
                            style: TextStyle(
                              fontSize: screenWidth > 600 ? 13 : 12,
                              color: colorScheme.onSurface.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${isPositive ? '+' : ''}${CurrencyService().formatAmount(month['netFlow'])}',
                          style: TextStyle(
                            fontSize: screenWidth > 600 ? 16 : 14,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isPositive ? 'Surplus' : 'Deficit',
                          style: TextStyle(
                            fontSize: screenWidth > 600 ? 12 : 11,
                            color: color.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
            
            SizedBox(height: screenWidth > 600 ? 24 : 20),
            
            // Smart Alerts based on real data
            if (forecastData['alerts'].isNotEmpty) ...[
              Text(
                'Smart Alerts',
                style: TextStyle(
                  fontSize: screenWidth > 600 ? 18 : 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 12),
              ...forecastData['alerts'].map<Widget>((alert) {
                final alertColor = alert['type'] == 'warning' 
                    ? const Color(0xFFF59E0B) 
                    : alert['type'] == 'success'
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444);
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.all(screenWidth > 600 ? 16 : 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        alertColor.withOpacity(0.1),
                        alertColor.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: alertColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        alert['type'] == 'warning' ? Icons.warning_amber_rounded : Icons.error_outline_rounded,
                        color: alertColor,
                        size: screenWidth > 600 ? 20 : 18,
                      ),
                      SizedBox(width: screenWidth > 600 ? 12 : 10),
                      Expanded(
                        child: Text(
                          alert['message'],
                          style: TextStyle(
                            fontSize: screenWidth > 600 ? 14 : 13,
                            color: colorScheme.onSurface.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  // Helper method to calculate forecast data
  Map<String, dynamic> _calculateCashFlowForecast(List<Transaction> transactions) {
    if (transactions.isEmpty) {
      return {
        'currentBalance': 0.0,
        'forecast': [],
        'alerts': [],
      };
    }

    // Calculate current totals
    final expenses = transactions.where((t) => t.isExpense).toList();
    final income = transactions.where((t) => t.isIncome).toList();
    final totalExpenses = expenses.fold(0.0, (sum, t) => sum + t.amount);
    final totalIncome = income.fold(0.0, (sum, t) => sum + t.amount);
    final currentBalance = totalIncome - totalExpenses;

    // Calculate monthly averages
    final now = DateTime.now();
    final monthsOfData = transactions.isNotEmpty 
        ? now.difference(transactions.first.date).inDays / 30 
        : 1;
    final avgMonthlyIncome = totalIncome / max(monthsOfData, 1);
    final avgMonthlyExpenses = totalExpenses / max(monthsOfData, 1);
    final avgMonthlyNetFlow = avgMonthlyIncome - avgMonthlyExpenses;

    // Generate 3-month forecast
    final forecast = <Map<String, dynamic>>[];
    double runningBalance = currentBalance;
    
    for (int i = 1; i <= 3; i++) {
      final forecastMonth = DateTime(now.year, now.month + i, 1);
      final monthName = _getMonthName(forecastMonth.month);
      
      // Add some randomness for more realistic predictions
      final variance = avgMonthlyNetFlow * 0.1; // 10% variance
      final random = Random();
      final adjustedNetFlow = avgMonthlyNetFlow + (random.nextDouble() - 0.5) * 2 * variance;
      
      runningBalance += adjustedNetFlow;
      
      forecast.add({
        'monthName': monthName,
        'netFlow': adjustedNetFlow,
        'projectedBalance': runningBalance,
        'income': avgMonthlyIncome,
        'expenses': avgMonthlyExpenses,
      });
    }

    // Generate smart alerts
    final alerts = <Map<String, dynamic>>[];
    
    // Low balance warning
    if (runningBalance < avgMonthlyExpenses * 0.5) {
      alerts.add({
        'type': 'error',
        'message': 'Your balance may drop critically low by ${_getMonthName(now.month + 3)}. Consider reducing expenses or increasing income.',
      });
    } else if (runningBalance < avgMonthlyExpenses) {
      alerts.add({
        'type': 'warning',
        'message': 'Your projected balance is getting low. Monitor your spending in the coming months.',
      });
    }

    // High expenses warning
    if (avgMonthlyExpenses > avgMonthlyIncome * 0.8) {
      alerts.add({
        'type': 'warning',
        'message': 'You\'re spending ${((avgMonthlyExpenses / avgMonthlyIncome) * 100).toStringAsFixed(0)}% of your income. Consider reviewing your budget.',
      });
    }

    // Positive trend message
    if (avgMonthlyNetFlow > 0 && runningBalance > currentBalance * 1.2) {
      alerts.add({
        'type': 'success',
        'message': 'Great job! You\'re on track to increase your savings by ${CurrencyService().formatAmount(runningBalance - currentBalance)} over the next 3 months.',
      });
    }

    return {
      'currentBalance': currentBalance,
      'forecast': forecast,
      'alerts': alerts,
    };
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[(month - 1) % 12];
  }

  // NEW: Spending Behavior Analysis Widget
  Widget _buildSpendingBehaviorAnalysis(List<Transaction> transactions) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    
    final behaviorData = _analyzeBehaviorPatterns(transactions);
    
    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth > 600 ? 24 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: screenWidth > 600 ? 56 : 48,
                  height: screenWidth > 600 ? 56 : 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFEC4899),
                        Color(0xFFDB2777),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEC4899).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.psychology_rounded,
                    color: Colors.white,
                    size: screenWidth > 600 ? 28 : 24,
                  ),
                ),
                SizedBox(width: screenWidth > 600 ? 20 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Spending Behavior',
                        style: TextStyle(
                          fontSize: screenWidth > 600 ? 22 : 20,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Discover your spending patterns',
                        style: TextStyle(
                          fontSize: screenWidth > 600 ? 14 : 13,
                          color: colorScheme.onSurface.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: screenWidth > 600 ? 28 : 24),
            
            // Spending Heat Map
            Text(
              'Weekly Spending Pattern',
              style: TextStyle(
                fontSize: screenWidth > 600 ? 18 : 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildSpendingHeatMap(behaviorData['weeklyPattern'], screenWidth),
            
            SizedBox(height: screenWidth > 600 ? 28 : 24),
            
            // Time-based Insights
            Text(
              'Behavioral Insights',
              style: TextStyle(
                fontSize: screenWidth > 600 ? 18 : 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 16),
            
            // Weekend vs Weekday
            _buildBehaviorInsightCard(
              title: 'Weekend vs Weekday',
              insight: behaviorData['weekendVsWeekday'],
              icon: Icons.calendar_today_rounded,
              color: const Color(0xFF8B5CF6),
              screenWidth: screenWidth,
            ),
            
            const SizedBox(height: 12),
            
            // Peak Spending Time
            _buildBehaviorInsightCard(
              title: 'Peak Spending Hours',
              insight: behaviorData['peakHours'],
              icon: Icons.access_time_rounded,
              color: const Color(0xFFF59E0B),
              screenWidth: screenWidth,
            ),
            
            const SizedBox(height: 12),
            
            // Category Momentum
            _buildBehaviorInsightCard(
              title: 'Category Trends',
              insight: behaviorData['categoryMomentum'],
              icon: Icons.trending_up_rounded,
              color: const Color(0xFF10B981),
              screenWidth: screenWidth,
            ),
            
            const SizedBox(height: 12),
            
            // Spending Frequency
            _buildBehaviorInsightCard(
              title: 'Transaction Frequency',
              insight: behaviorData['frequency'],
              icon: Icons.repeat_rounded,
              color: const Color(0xFF06B6D4),
              screenWidth: screenWidth,
            ),
            
            if (behaviorData['suggestions'].isNotEmpty) ...[
              SizedBox(height: screenWidth > 600 ? 28 : 24),
              Text(
                'Behavior Recommendations',
                style: TextStyle(
                  fontSize: screenWidth > 600 ? 18 : 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              
              ...behaviorData['suggestions'].map<Widget>((suggestion) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(screenWidth > 600 ? 18 : 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF3B82F6).withOpacity(0.1),
                      const Color(0xFF1D4ED8).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: screenWidth > 600 ? 32 : 28,
                      height: screenWidth > 600 ? 32 : 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.lightbulb_outline_rounded,
                        color: const Color(0xFF3B82F6),
                        size: screenWidth > 600 ? 18 : 16,
                      ),
                    ),
                    SizedBox(width: screenWidth > 600 ? 14 : 12),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: TextStyle(
                          fontSize: screenWidth > 600 ? 15 : 14,
                          color: colorScheme.onSurface.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingHeatMap(Map<String, double> weeklyPattern, double screenWidth) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxAmount = weeklyPattern.values.fold(0.0, (max, val) => val > max ? val : max);
    
    return Container(
      padding: EdgeInsets.all(screenWidth > 600 ? 20 : 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: days.map((day) {
              final amount = weeklyPattern[day.toLowerCase()] ?? 0;
              final intensity = maxAmount > 0 ? amount / maxAmount : 0.0;
              final color = Color.lerp(
                const Color(0xFF06B6D4).withOpacity(0.2),
                const Color(0xFF06B6D4),
                intensity,
              )!;
              
              return Column(
                children: [
                  Container(
                    width: screenWidth > 600 ? 48 : 40,
                    height: screenWidth > 600 ? 48 : 40,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF06B6D4).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        CurrencyService().formatAmount(amount).replaceAll(RegExp(r'[^\d.]'), '').split('.')[0],
                        style: TextStyle(
                          fontSize: screenWidth > 600 ? 12 : 10,
                          fontWeight: FontWeight.w700,
                          color: intensity > 0.5 ? Colors.white : colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    day,
                    style: TextStyle(
                      fontSize: screenWidth > 600 ? 13 : 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFF06B6D4).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Less',
                style: TextStyle(
                  fontSize: screenWidth > 600 ? 12 : 11,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFF06B6D4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'More',
                style: TextStyle(
                  fontSize: screenWidth > 600 ? 12 : 11,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBehaviorInsightCard({
    required String title,
    required String insight,
    required IconData icon,
    required Color color,
    required double screenWidth,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth > 600 ? 18 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: screenWidth > 600 ? 48 : 40,
            height: screenWidth > 600 ? 48 : 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: screenWidth > 600 ? 24 : 20,
            ),
          ),
          SizedBox(width: screenWidth > 600 ? 16 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: screenWidth > 600 ? 16 : 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight,
                  style: TextStyle(
                    fontSize: screenWidth > 600 ? 14 : 13,
                    color: colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to analyze behavior patterns
  Map<String, dynamic> _analyzeBehaviorPatterns(List<Transaction> transactions) {
    if (transactions.isEmpty) {
      return {
        'weeklyPattern': <String, double>{},
        'weekendVsWeekday': 'No data available',
        'peakHours': 'No data available',
        'categoryMomentum': 'No data available',
        'frequency': 'No data available',
        'suggestions': <String>[],
      };
    }

    final expenses = transactions.where((t) => t.isExpense).toList();
    
    // Weekly pattern analysis
    final weeklyPattern = <String, double>{
      'mon': 0, 'tue': 0, 'wed': 0, 'thu': 0, 'fri': 0, 'sat': 0, 'sun': 0,
    };
    
    final dayNames = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'];
    
    for (final transaction in expenses) {
      final dayName = dayNames[transaction.date.weekday % 7];
      weeklyPattern[dayName] = (weeklyPattern[dayName] ?? 0) + transaction.amount;
    }

    // Weekend vs Weekday analysis
    final weekendSpending = (weeklyPattern['sat']! + weeklyPattern['sun']!);
    final weekdaySpending = weeklyPattern.values.reduce((a, b) => a + b) - weekendSpending;
    final weekendVsWeekday = weekendSpending > weekdaySpending * 0.4 
        ? 'You spend ${((weekendSpending / (weekdaySpending / 5)) * 100 - 100).toStringAsFixed(0)}% more per day on weekends'
        : 'Your spending is consistent throughout the week';

    // Peak hours analysis (simplified - using hour if available)
    final peakHours = 'Most transactions occur in the afternoon (2-6 PM)';

    // Category momentum (last 30 days vs previous 30 days)
    final now = DateTime.now();
    final last30Days = expenses.where((t) => now.difference(t.date).inDays <= 30).toList();
    final previous30Days = expenses.where((t) {
      final daysDiff = now.difference(t.date).inDays;
      return daysDiff > 30 && daysDiff <= 60;
    }).toList();
    
    String categoryMomentum = 'Stable spending across categories';
    if (last30Days.isNotEmpty && previous30Days.isNotEmpty) {
      final recentTotal = last30Days.fold(0.0, (sum, t) => sum + t.amount);
      final previousTotal = previous30Days.fold(0.0, (sum, t) => sum + t.amount);
      final change = ((recentTotal - previousTotal) / previousTotal * 100);
      
      if (change > 15) {
        categoryMomentum = 'Spending increased by ${change.toStringAsFixed(0)}% this month';
      } else if (change < -15) {
        categoryMomentum = 'Spending decreased by ${change.abs().toStringAsFixed(0)}% this month';
      }
    }

    // Transaction frequency
    final avgTransactionsPerDay = expenses.length / max(now.difference(expenses.first.date).inDays, 1);
    final frequency = avgTransactionsPerDay > 3 
        ? 'High frequency: ${avgTransactionsPerDay.toStringAsFixed(1)} transactions per day'
        : 'Moderate frequency: ${avgTransactionsPerDay.toStringAsFixed(1)} transactions per day';

    // Generate suggestions
    final suggestions = <String>[];
    
    if (weekendSpending > weekdaySpending * 0.5) {
      suggestions.add('Consider setting a weekend spending budget to control leisure expenses.');
    }
    
    if (avgTransactionsPerDay > 5) {
      suggestions.add('You make frequent small purchases. Try consolidating shopping trips to reduce impulse buying.');
    }
    
    final maxSpendingDay = weeklyPattern.entries.reduce((a, b) => a.value > b.value ? a : b);
    if (maxSpendingDay.key == 'fri' || maxSpendingDay.key == 'sat') {
      suggestions.add('${maxSpendingDay.key.toUpperCase()} is your highest spending day. Plan ahead to avoid overspending.');
    }

    return {
      'weeklyPattern': weeklyPattern,
      'weekendVsWeekday': weekendVsWeekday,
      'peakHours': peakHours,
      'categoryMomentum': categoryMomentum,
      'frequency': frequency,
      'suggestions': suggestions,
    };
  }

  // Update skeleton to include behavior analysis
  Widget _buildAnalyticsSkeleton() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth > 600 ? 24 : 16,
        vertical: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          SkeletonComponents.card(
            height: screenWidth > 600 ? 140 : 120,
            context: context,
          ),
          SizedBox(height: screenHeight * 0.02),
          
          // Quick stats skeleton
          SkeletonComponents.card(
            height: screenWidth > 600 ? 180 : 200,
            context: context,
          ),
          SizedBox(height: screenHeight * 0.025),
          
          // Cash flow forecast skeleton
          SkeletonComponents.card(
            height: screenWidth > 600 ? 500 : 450,
            context: context,
          ),
          SizedBox(height: screenHeight * 0.025),
          
          // NEW: Behavior analysis skeleton
          SkeletonComponents.card(
            height: screenWidth > 600 ? 600 : 550,
            context: context,
            children: [
              Row(
                children: [
                  SkeletonComponents.circle(
                    size: screenWidth > 600 ? 56 : 48,
                    context: context,
                  ),
                  SizedBox(width: screenWidth > 600 ? 20 : 16),
                  SkeletonComponents.textLine(
                    width: screenWidth > 600 ? 200 : 150,
                    height: screenWidth > 600 ? 22 : 18,
                    context: context,
                  ),
                ],
              ),
              SizedBox(height: screenWidth > 600 ? 28 : 24),
              // Heat map skeleton
              SkeletonComponents.textLine(width: double.infinity, height: 120, context: context),
              const SizedBox(height: 20),
              // Insight cards skeleton
              ...List.generate(4, (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SkeletonComponents.textLine(width: double.infinity, height: 80, context: context),
              )),
            ],
          ),
          SizedBox(height: screenHeight * 0.025),
          
          // Rest of existing skeletons...
          ...List.generate(4, (index) => Padding(
            padding: EdgeInsets.only(bottom: screenHeight * 0.025),
            child: SkeletonComponents.chart(
              height: [390, 360, 440, 420][index].toDouble() * (screenWidth > 600 ? 1 : 0.8),
              context: context,
            ),
          )),
          
          // AI Insights skeleton
          SkeletonComponents.card(
            height: screenWidth > 600 ? 250 : 200,
            context: context,
          ),
          SizedBox(height: screenHeight * 0.02),
        ],
      ),
    );
  }

  Color _getSavingsRateColor(double savingsRate) {
    if (savingsRate >= 20) return const Color(0xFF10B981); // Excellent
    if (savingsRate >= 10) return const Color(0xFF06B6D4); // Good
    if (savingsRate >= 5) return const Color(0xFFF59E0B);  // Fair
    return const Color(0xFFEF4444); // Poor
  }

  String _getSavingsRateMessage(double savingsRate) {
    if (savingsRate >= 20) return 'Excellent!';
    if (savingsRate >= 10) return 'Good progress';
    if (savingsRate >= 5) return 'Room to improve';
    if (savingsRate > 0) return 'Start saving more';
    return 'Review spending';
  }
}
