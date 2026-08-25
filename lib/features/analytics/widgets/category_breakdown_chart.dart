import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/services/currency_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CategoryBreakdownChart extends StatefulWidget {
  final List<Transaction> transactions;

  const CategoryBreakdownChart({super.key, required this.transactions});

  @override
  State<CategoryBreakdownChart> createState() => _CategoryBreakdownChartState();
}

class _CategoryBreakdownChartState extends State<CategoryBreakdownChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.transactions.isEmpty) {
      return _buildEmptyState();
    }

    final categoryData = _getCategoryData();
    final totalSpending =
        categoryData.fold(0.0, (sum, item) => sum + (item['amount'] as double));

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: Stack(
            children: [
              PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          touchedIndex = -1;
                          return;
                        }
                        touchedIndex = pieTouchResponse
                            .touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 4,
                  centerSpaceRadius: 60, // Donut style
                  sections: _getPieSections(categoryData),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      CurrencyService().formatAmountCompact(totalSpending),
                      style: TextStyle(
                        fontSize: 20,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildLegend(categoryData, context),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      decoration: AppTheme.surfaceDecoration(
        context,
        radius: AppTheme.cardRadius,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.pieChart,
              size: 48,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3),
            ),
            const SizedBox(height: 8),
            Text(
              'No category data',
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getCategoryData() {
    final Map<String, double> categoryTotals = {};

    for (final transaction in widget.transactions) {
      if (transaction.isExpense) {
        categoryTotals[transaction.category] =
            (categoryTotals[transaction.category] ?? 0) + transaction.amount;
      }
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Consolidate smaller categories into "Other" if too many
    if (sortedCategories.length > 5) {
      final top5 = sortedCategories.take(5).toList();
      final otherValue =
          sortedCategories.skip(5).fold(0.0, (sum, entry) => sum + entry.value);

      final result = top5
          .map((entry) => {
                'category': entry.key,
                'amount': entry.value,
              })
          .toList();

      if (otherValue > 0) {
        result.add({
          'category': 'Other',
          'amount': otherValue,
        });
      }
      return result;
    }

    return sortedCategories
        .map((entry) => {
              'category': entry.key,
              'amount': entry.value,
            })
        .toList();
  }

  static const List<Color> _categoryColors = [
    AppColors.primary,
    Color(0xFF19A7A0), // Teal
    Color(0xFF7C5CFC), // Violet
    Color(0xFFF59E0B), // Amber
    Color(0xFFE76F51), // Coral
    Color(0xFF16A34A), // Green
    Color(0xFF3B82F6), // Sky blue
  ];

  List<PieChartSectionData> _getPieSections(
      List<Map<String, dynamic>> categoryData) {
    final colors = _categoryColors;

    final total =
        categoryData.fold(0.0, (sum, item) => sum + (item['amount'] as double));

    return categoryData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final isTouched = index == touchedIndex;
      final fontSize = isTouched
          ? 16.0
          : 0.0; // Hide titles on chart, show only on interaction or legend
      final radius = isTouched ? 28.0 : 20.0;
      final color = colors[index % colors.length];
      final percentage = ((data['amount'] as double) / total * 100);

      return PieChartSectionData(
        color: color,
        value: data['amount'],
        title: '${percentage.toStringAsFixed(1)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        showTitle: false, // Cleaner look, rely on legend
      );
    }).toList();
  }

  Widget _buildLegend(
      List<Map<String, dynamic>> categoryData, BuildContext context) {
    final colors = _categoryColors;

    final total =
        categoryData.fold(0.0, (sum, item) => sum + (item['amount'] as double));
    final halfLength = (categoryData.length / 2).ceil();
    final firstHalf = categoryData.take(halfLength).toList();
    final secondHalf = categoryData.skip(halfLength).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
            child: Column(
                children:
                    _buildLegendItems(firstHalf, colors, 0, total, context))),
        const SizedBox(width: 16),
        Expanded(
            child: Column(
                children: _buildLegendItems(
                    secondHalf, colors, halfLength, total, context))),
      ],
    );
  }

  List<Widget> _buildLegendItems(List<Map<String, dynamic>> items,
      List<Color> colors, int startIndex, double total, BuildContext context) {
    return items.asMap().entries.map((entry) {
      final index = entry.key + startIndex;
      final data = entry.value;
      final color = colors[index % colors.length];
      final percentage = ((data['amount'] as double) / total * 100);

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
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
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}% • ${CurrencyService().formatAmountCompact(data['amount'])}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
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
