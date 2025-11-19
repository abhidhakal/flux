import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/services/currency_service.dart';

class CategoryBreakdownChart extends StatelessWidget {
  final List<Transaction> transactions;

  const CategoryBreakdownChart({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radius12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pie_chart,
                size: 48,
                color: AppColors.textSecondary,
              ),
              SizedBox(height: AppTheme.spacing8),
              Text(
                'No category data available',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: AppTheme.spacing4),
              Text(
                'Add some expense transactions to see category breakdown',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final categoryData = _getCategoryData();
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: _getPieSections(categoryData),
                  pieTouchData: PieTouchData(
                    enabled: true,
                    touchCallback: (event, response) {
                      // Handle touch interactions if needed
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildLegend(categoryData),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getCategoryData() {
    final Map<String, double> categoryTotals = {};
    
    for (final transaction in transactions) {
      if (transaction.isExpense) {
        categoryTotals[transaction.category] = 
            (categoryTotals[transaction.category] ?? 0) + transaction.amount;
      }
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedCategories.take(6).map((entry) {
      final total = categoryTotals.values.fold(0.0, (sum, amount) => sum + amount);
      final percentage = (entry.value / total * 100);
      return {
        'category': entry.key,
        'amount': entry.value,
        'percentage': percentage,
      };
    }).toList();
  }

  List<PieChartSectionData> _getPieSections(List<Map<String, dynamic>> categoryData) {
    final colors = [
      AppColors.primary,
      AppColors.success,
      AppColors.error,
      AppColors.warning,
      AppColors.secondary,
      AppColors.accent,
      const Color(0xFF9C27B0), // Purple
      const Color(0xFF607D8B), // Blue Grey
      const Color(0xFFFF9800), // Orange
      const Color(0xFF795548), // Brown
    ];

    return categoryData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final color = colors[index % colors.length];
      
      return PieChartSectionData(
        color: color,
        value: data['amount'],
        title: '${data['percentage'].toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titlePositionPercentageOffset: 0.6,
      );
    }).toList();
  }

  List<Widget> _buildLegend(List<Map<String, dynamic>> categoryData) {
    final colors = [
      AppColors.primary,
      AppColors.success,
      AppColors.error,
      AppColors.warning,
      AppColors.secondary,
      AppColors.accent,
      const Color(0xFF9C27B0), // Purple
      const Color(0xFF607D8B), // Blue Grey
      const Color(0xFFFF9800), // Orange
      const Color(0xFF795548), // Brown
    ];

    return categoryData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final color = colors[index % colors.length];
      
      return Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['category'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    CurrencyService().formatAmount(data['amount']).replaceAll('.00', ''),
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
