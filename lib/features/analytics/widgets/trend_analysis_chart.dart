import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/services/currency_service.dart';

class TrendAnalysisChart extends StatelessWidget {
  final List<Transaction> transactions;

  const TrendAnalysisChart({
    super.key, 
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radius12),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart,
                size: 48,
                color: AppColors.textSecondary,
              ),
              SizedBox(height: AppTheme.spacing8),
              Text(
                'No trend data available',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: AppTheme.spacing4),
              Text(
                'Add some records to see income vs expense trends',
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

    final monthlyData = _getMonthlyData();
    final maxAmount = _getMaxY(monthlyData);
    final interval = _getYAxisInterval(maxAmount);
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius12),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildLegendItem('Income', AppColors.success),
              const SizedBox(width: AppTheme.spacing16),
              _buildLegendItem('Expenses', AppColors.error),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxAmount,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final monthData = monthlyData[group.x.toInt()];
                      final isIncome = rodIndex == 0;
                      final amount = isIncome ? monthData['income'] : monthData['expense'];
                      final label = isIncome ? 'Income' : 'Expenses';
                      
                      return BarTooltipItem(
                        '$label\n${CurrencyService().formatAmount(amount).replaceAll('.00', '')}',
                        TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        if (value.toInt() >= 0 && value.toInt() < monthlyData.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: AppTheme.spacing8),
                            child: Text(
                              monthlyData[value.toInt()]['month'],
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 9, // Reduced font size for consistency
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 35,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      interval: interval,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: AppTheme.spacing4),
                          child: Text(
                            CurrencyService().formatAmount(value).replaceAll('.00', ''),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 9, // Reduced font size to prevent overflow
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _getBarGroups(monthlyData),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.05),
                      strokeWidth: 1,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getMonthlyData() {
    final Map<String, Map<String, double>> monthlyData = {};
    
    // Add expenses
    for (final transaction in transactions) {
      if (transaction.isExpense) {
        final monthKey = '${transaction.date.year}-${transaction.date.month.toString().padLeft(2, '0')}';
        if (!monthlyData.containsKey(monthKey)) {
          monthlyData[monthKey] = {'income': 0, 'expense': 0};
        }
        monthlyData[monthKey]!['expense'] = monthlyData[monthKey]!['expense']! + transaction.amount;
      }
    }

    for (final transaction in transactions.where((t) => t.isIncome)) {
      final monthKey =
          '${transaction.date.year}-${transaction.date.month.toString().padLeft(2, '0')}';
      if (!monthlyData.containsKey(monthKey)) {
        monthlyData[monthKey] = {'income': 0, 'expense': 0};
      }
      monthlyData[monthKey]!['income'] =
          monthlyData[monthKey]!['income']! + transaction.amount;
    }

    final sortedMonths = monthlyData.keys.toList()..sort();
    // Limit to last 6 months
    final displayMonths = sortedMonths.length > 6 ? sortedMonths.sublist(sortedMonths.length - 6) : sortedMonths;

    return displayMonths.map((month) {
      final parts = month.split('-');
      final monthName = _getMonthName(int.parse(parts[1]));
      return {
        'month': monthName,
        'income': monthlyData[month]!['income']!,
        'expense': monthlyData[month]!['expense']!,
      };
    }).toList();
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  List<BarChartGroupData> _getBarGroups(List<Map<String, dynamic>> monthlyData) {
    return monthlyData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data['income'],
            color: AppColors.success,
            width: 8,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          BarChartRodData(
            toY: data['expense'],
            color: AppColors.error,
            width: 8,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();
  }

  double _getMaxY(List<Map<String, dynamic>> monthlyData) {
    if (monthlyData.isEmpty) return 1000;
    
    double maxAmount = 0;
    for (final data in monthlyData) {
      final max = data['income'] > data['expense'] ? data['income'].toDouble() : data['expense'].toDouble();
      if (max > maxAmount) maxAmount = max;
    }
    
    // Round up to a nice number
    final interval = _getYAxisInterval(maxAmount);
    return ((maxAmount / interval).ceil() + 1) * interval;
  }

  double _getYAxisInterval(double maxAmount) {
    if (maxAmount <= 0) return 100;
    if (maxAmount <= 500) return 100;
    if (maxAmount <= 1000) return 250;
    if (maxAmount <= 2500) return 500;
    if (maxAmount <= 5000) return 1000;
    if (maxAmount <= 10000) return 2500;
    if (maxAmount <= 25000) return 5000;
    if (maxAmount <= 50000) return 10000;
    if (maxAmount <= 100000) return 25000;
    return 50000;
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppTheme.spacing4),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
