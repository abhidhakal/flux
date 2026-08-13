import 'package:flutter/material.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/models/budget_model.dart';
import '../../../core/models/financial_snapshot.dart';
import '../../../core/models/goal_model.dart';
import '../../../core/services/financial_insights_service.dart';
import '../../goals/screens/goals_screen.dart';
import '../../main/widgets/budgets_screen.dart';
import '../../main/widgets/transactions_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ForYouActionsCard extends StatelessWidget {
  final FinancialSnapshot snapshot;
  final List<Budget> budgets;
  final List<Goal> goals;

  const ForYouActionsCard({
    super.key,
    required this.snapshot,
    required this.budgets,
    required this.goals,
  });

  @override
  Widget build(BuildContext context) {
    final insights = FinancialInsightsService()
        .generate(snapshot: snapshot, budgets: budgets, goals: goals)
        .take(3)
        .toList();
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: AppTheme.surfaceDecoration(context, radius: 20, subtle: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                insights.isEmpty ? 'You are on track' : 'For you',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const Spacer(),
              if (insights.isNotEmpty)
                Text(
                  '${insights.length} action${insights.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            insights.isEmpty
                ? 'Nothing needs your attention today.'
                : 'Small steps to keep your money moving in the right direction.',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          if (insights.isNotEmpty) const SizedBox(height: 12),
          for (var index = 0; index < insights.length; index++) ...[
            if (index > 0)
              Divider(
                height: 1,
                indent: 44,
                color: colorScheme.outline.withValues(alpha: 0.12),
              ),
            _InsightRow(insight: insights[index], featured: index == 0),
          ],
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final FinancialInsight insight;
  final bool featured;

  const _InsightRow({required this.insight, required this.featured});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = switch (insight.tone) {
      InsightTone.positive => AppColors.success,
      InsightTone.attention => AppColors.warning,
      InsightTone.neutral => colorScheme.primary,
    };

    return Padding(
      padding: EdgeInsets.symmetric(vertical: featured ? 4 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              insight.tone == InsightTone.attention
                  ? LucideIcons.alertTriangle
                  : insight.tone == InsightTone.positive
                      ? LucideIcons.trendingUp
                      : LucideIcons.target,
              color: color,
              size: 17,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: featured ? 14 : 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  insight.message,
                  maxLines: featured ? 3 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 7),
                InkWell(
                  onTap: () => _openAction(context, insight.action),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          insight.actionLabel,
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(LucideIcons.chevronRight,
                            size: 15, color: colorScheme.primary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openAction(BuildContext context, FinancialInsightAction action) {
    final Widget destination = switch (action) {
      FinancialInsightAction.budgets => const BudgetsScreen(),
      FinancialInsightAction.goals => const GoalsScreen(),
      FinancialInsightAction.transactions => const TransactionsScreen(),
    };
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }
}
