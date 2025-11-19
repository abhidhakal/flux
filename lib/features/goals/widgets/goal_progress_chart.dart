import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/goal_model.dart';

class GoalProgressChart extends StatelessWidget {
  final List<Goal> goals;

  const GoalProgressChart({super.key, required this.goals});

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) {
      return const Center(
        child: Text(
          'No goals to display',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final activeGoals = goals.where((g) => g.status == GoalStatus.active).toList();
    
    if (activeGoals.isEmpty) {
      return const Center(
        child: Text(
          'No active goals to display',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBorder: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.3)),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final goal = activeGoals[groupIndex];
              return BarTooltipItem(
                '${goal.name}\n${goal.progressPercentage.toStringAsFixed(1)}%',
                const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
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
                if (value.toInt() >= 0 && value.toInt() < activeGoals.length) {
                  final goal = activeGoals[value.toInt()];
                  return Container(
                    width: 60,
                    child: Text(
                      goal.name.length > 8 
                          ? '${goal.name.substring(0, 8)}...' 
                          : goal.name,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 40,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              interval: 25,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  '${value.toInt()}%',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.2)),
        ),
        barGroups: _getBarGroups(activeGoals),
        gridData: FlGridData(
          show: true,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.textSecondary.withValues(alpha: 0.1),
              strokeWidth: 1,
            );
          },
        ),
      ),
    );
  }

  List<BarChartGroupData> _getBarGroups(List<Goal> activeGoals) {
    return activeGoals.asMap().entries.map((entry) {
      final index = entry.key;
      final goal = entry.value;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: goal.progressPercentage,
            color: Color(goal.color),
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();
  }
}
