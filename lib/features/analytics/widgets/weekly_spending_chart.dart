import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/services/currency_service.dart';

class WeeklySpendingChart extends StatelessWidget {
  final List<Transaction> transactions;

  const WeeklySpendingChart({super.key, required this.transactions});

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
                Icons.calendar_view_week,
                size: 48,
                color: AppColors.textSecondary,
              ),
              SizedBox(height: AppTheme.spacing8),
              Text(
                'No weekly data available',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: AppTheme.spacing4),
              Text(
                'Add some transactions to see weekly spending patterns',
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

    final weeklyData = _getWeeklyData();
    final maxAmount = _getMaxY(weeklyData);
    final interval = _getYAxisInterval(maxAmount);
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius24),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        children: [
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
                      final dayData = weeklyData[group.x.toInt()];
                      final date = dayData['date'] as DateTime;
                      final dateString = '${date.day}/${date.month}';
                      return BarTooltipItem(
                        '$dateString (${dayData['dayName']})\n${CurrencyService().formatAmount(dayData['amount']).replaceAll('.00', '')}',
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
                        if (value.toInt() >= 0 && value.toInt() < weeklyData.length) {
                          final dayData = weeklyData[value.toInt()];
                          final dayName = dayData['dayName'];
                          return Padding(
                            padding: const EdgeInsets.only(top: AppTheme.spacing8),
                            child: Text(
                              dayName,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      interval: interval,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text(
                          CurrencyService().formatAmount(value).replaceAll('.00', ''),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _getBarGroups(weeklyData),
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

  List<Map<String, dynamic>> _getWeeklyData() {
    final Map<String, double> dailyTotals = {};
    
    for (final transaction in transactions) {
      if (transaction.isExpense) {
        // Get the date string (YYYY-MM-DD format)
        final dateString = '${transaction.date.year}-${transaction.date.month.toString().padLeft(2, '0')}-${transaction.date.day.toString().padLeft(2, '0')}';
        dailyTotals[dateString] = (dailyTotals[dateString] ?? 0) + transaction.amount;
      }
    }

    // Get the last 7 days of data
    final days = <Map<String, dynamic>>[];
    final now = DateTime.now();
    
    for (int i = 6; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day - i);
      final dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      
      days.add({
        'date': date,
        'dayName': dayNames[date.weekday - 1],
        'amount': dailyTotals[dateString] ?? 0.0,
      });
    }
    
    return days;
  }

  List<BarChartGroupData> _getBarGroups(List<Map<String, dynamic>> weeklyData) {
    return weeklyData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data['amount'],
            color: AppColors.primary,
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();
  }

  double _getMaxY(List<Map<String, dynamic>> weeklyData) {
    if (weeklyData.isEmpty) return 1000;
    final maxAmount = weeklyData.map((data) => data['amount'] as double).reduce((a, b) => a > b ? a : b);
    return maxAmount * 1.2; // Add 20% padding
  }

  double _getYAxisInterval(double maxAmount) {
    if (maxAmount <= 100) return 25;
    if (maxAmount <= 500) return 100;
    if (maxAmount <= 1000) return 200;
    if (maxAmount <= 5000) return 500;
    if (maxAmount <= 10000) return 1000;
    return 2000;
  }
}
