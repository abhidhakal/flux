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
      return _buildEmptyState(context);
    }

    final monthlyData = _getMonthlyData();
    final maxAmount = _getMaxY(monthlyData);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Text(
                'Spending Trend',
                 style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.2,
                ),
            ),
            const SizedBox(height: 24),
            AspectRatio(
            aspectRatio: 1.70,
            child: LineChart(
                LineChartData(
                gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _getYAxisInterval(maxAmount),
                    getDrawingHorizontalLine: (value) {
                    return FlLine(
                        color: colorScheme.outline.withOpacity(0.1),
                        strokeWidth: 1,
                        dashArray: [5, 5]
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
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (double value, TitleMeta meta) {
                        if (value.toInt() >= 0 && value.toInt() < monthlyData.length) {
                             return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                    monthlyData[value.toInt()]['month'],
                                    style: TextStyle(
                                    color: colorScheme.onSurface.withOpacity(0.5),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    ),
                                ),
                             );
                        }
                        return const Text('');
                        },
                    ),
                    ),
                    leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false), // Clean look, hide left axis values or keep minimal
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
                    getTooltipColor: (touchedSpot) => colorScheme.surface,

                    getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                        final index = spot.x.toInt();
                        if (index >= 0 && index < monthlyData.length) {
                            final data = monthlyData[index];
                            return LineTooltipItem(
                            '${data['month']}\n',
                            TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.6),
                                fontWeight: FontWeight.normal,
                                fontSize: 12,
                            ),
                            children: [
                                TextSpan(
                                text: CurrencyService().formatAmount(data['amount']).replaceAll('.00', ''),
                                style: TextStyle(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                ),
                                ),
                            ],
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
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                        colors: [
                            AppColors.primary.withOpacity(0.15),
                            AppColors.primary.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        ),
                    ),
                    ),
                ],
                ),
            ),
            ),
        ],
    );
  }

   Widget _buildEmptyState(BuildContext context) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radius12),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.show_chart_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: 8),
              Text(
                'No spending data',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
   }

  List<Map<String, dynamic>> _getMonthlyData() {
    final Map<String, double> monthlyTotals = {};
    
    // Process last 6 months
    final now = DateTime.now();
    for (int i = 5; i >= 0; i--) {
        final date = DateTime(now.year, now.month - i, 1);
        final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        monthlyTotals[key] = 0.0;
    }
    
    for (final transaction in transactions) {
      if (transaction.isExpense) {
        final monthKey = '${transaction.date.year}-${transaction.date.month.toString().padLeft(2, '0')}';
        if (monthlyTotals.containsKey(monthKey)) {
             monthlyTotals[monthKey] = (monthlyTotals[monthKey]!) + transaction.amount;
        }
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
    return maxAmount * 1.2; 
  }

  double _getYAxisInterval(double maxAmount) {
     if (maxAmount == 0) return 100;
    return maxAmount / 4;
  }
}
