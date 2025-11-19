import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/services/currency_service.dart';

class SpendingChart extends StatelessWidget {
  final List<Transaction> transactions;

  const SpendingChart({super.key, required this.transactions});

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
                Icons.show_chart,
                size: 48,
                color: AppColors.textSecondary,
              ),
              SizedBox(height: AppTheme.spacing8),
              Text(
                'No spending data available',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: AppTheme.spacing4),
              Text(
                'Add some transactions to see your spending trends',
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius12),
        border: Border.all(color: AppColors.border),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppColors.border,
                strokeWidth: 1,
              );
            },
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
                reservedSize: 35,
                interval: 1,
                getTitlesWidget: (double value, TitleMeta meta) {
                  if (value.toInt() >= 0 && value.toInt() < monthlyData.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: AppTheme.spacing8),
                      child: Text(
                        monthlyData[value.toInt()]['month'],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: interval,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return Padding(
                    padding: const EdgeInsets.only(right: AppTheme.spacing8),
                    child: Text(
                      CurrencyService().formatAmount(value).replaceAll('.00', ''),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
                reservedSize: 60,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (monthlyData.length - 1).toDouble(),
          minY: 0,
          maxY: maxAmount,
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              tooltipBorder: BorderSide(color: AppColors.border),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.x.toInt();
                  if (index >= 0 && index < monthlyData.length) {
                    final data = monthlyData[index];
                    return LineTooltipItem(
                      '${data['month']}\n${CurrencyService().formatAmount(data['amount']).replaceAll('.00', '')}',
                      const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }
                  return null;
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: _getSpots(monthlyData),
              isCurved: true,
              curveSmoothness: 0.35,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.7),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 6,
                    color: AppColors.primary,
                    strokeWidth: 2,
                    strokeColor: AppColors.surface,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.2),
                    AppColors.primary.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getMonthlyData() {
    final Map<String, double> monthlyTotals = {};
    
    for (final transaction in transactions) {
      if (transaction.isExpense) {
        final monthKey = '${transaction.date.year}-${transaction.date.month.toString().padLeft(2, '0')}';
        monthlyTotals[monthKey] = (monthlyTotals[monthKey] ?? 0) + transaction.amount;
      }
    }

    final sortedMonths = monthlyTotals.keys.toList()..sort();
    return sortedMonths.map((month) {
      final parts = month.split('-');
      final monthName = _getMonthName(int.parse(parts[1]));
      return {
        'month': monthName,
        'amount': monthlyTotals[month]!,
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

  List<FlSpot> _getSpots(List<Map<String, dynamic>> monthlyData) {
    return monthlyData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value['amount']);
    }).toList();
  }

  double _getMaxY(List<Map<String, dynamic>> monthlyData) {
    if (monthlyData.isEmpty) return 1000;
    final maxAmount = monthlyData.map((data) => data['amount'] as double).reduce((a, b) => a > b ? a : b);
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
