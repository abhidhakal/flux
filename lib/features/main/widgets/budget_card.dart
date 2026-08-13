import 'package:flutter/material.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/models/budget_model.dart';
import '../../../core/services/currency_service.dart';
import '../../budget/screens/edit_budget_screen.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_icon_badge.dart';
import '../../../shared/widgets/app_status_pill.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class BudgetCard extends StatelessWidget {
  final Budget budget;
  final bool muted;
  final VoidCallback onDelete;

  const BudgetCard({
    super.key,
    required this.budget,
    required this.onDelete,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final spent = budget.spent;
    final percentage = budget.progressPercentage;
    final isOverBudget = budget.isOverBudget;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      onTap: () => EditBudgetScreen.showEditBudgetSheet(context, budget),
      onLongPress: onDelete,
      padding: const EdgeInsets.all(18),
      subtle: muted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with icon and title
          Row(
            children: [
              AppIconBadge(
                icon: muted
                    ? LucideIcons.pauseCircle
                    : isOverBudget
                        ? LucideIcons.alertTriangle
                        : percentage > 80
                            ? LucideIcons.trendingUp
                            : LucideIcons.wallet,
                color: muted
                    ? colorScheme.onSurface.withValues(alpha: 0.65)
                    : isOverBudget
                        ? AppColors.error
                        : percentage > 80
                            ? AppColors.warning
                            : AppColors.primary,
                size: AppIconBadgeSize.small,
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget.name,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface
                            .withValues(alpha: muted ? 0.7 : 1),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '${budget.category} • ${_periodLabel(budget.period.name)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        if (!budget.isActive) ...[
                          const SizedBox(width: 8),
                          AppStatusPill(
                            label: 'Inactive',
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing8),
          // Amount row
          Row(
            children: [
              Expanded(
                child: _amountSummary(
                  context,
                  label: 'Spent',
                  value: CurrencyService().formatAmount(spent),
                  color: muted
                      ? colorScheme.onSurface.withValues(alpha: 0.7)
                      : colorScheme.onSurface,
                ),
              ),
              Expanded(
                child: _amountSummary(
                  context,
                  label: isOverBudget ? 'Over by' : 'Remaining',
                  value: CurrencyService().formatAmount(
                    isOverBudget ? -budget.remaining : budget.remaining,
                  ),
                  color: muted
                      ? colorScheme.onSurface.withValues(alpha: 0.7)
                      : isOverBudget
                          ? AppColors.error
                          : AppColors.success,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: (percentage / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: colorScheme.outline.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                muted
                    ? colorScheme.onSurface.withValues(alpha: 0.3)
                    : isOverBudget
                        ? AppColors.error
                        : percentage > 80
                            ? AppColors.warning
                            : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${percentage.toStringAsFixed(1)}% used',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: muted
                      ? colorScheme.onSurface.withValues(alpha: 0.65)
                      : isOverBudget
                          ? AppColors.error
                          : colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          if (!muted && !isOverBudget) _buildPaceLine(context, percentage),
          if (!muted && budget.hasWeeklyTarget)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Weekly target: ${CurrencyService().formatAmount(budget.weeklyTarget)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
            ),
          if (!muted && budget.hasTemporaryAdjustment)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${budget.temporaryAdjustment >= 0 ? 'Includes' : 'Subtracts'} ${CurrencyService().formatAmount(budget.temporaryAdjustment.abs())} temporary adjustment',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          if (isOverBudget && !muted)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Over budget by ${CurrencyService().formatAmount(-budget.remaining)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          if (budget.hasRollover)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Includes ${CurrencyService().formatAmount(budget.rolloverAmount)} rollover',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.success,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _periodLabel(String name) =>
      name.isEmpty ? name : name[0].toUpperCase() + name.substring(1);

  Widget _amountSummary(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
    bool alignEnd = false,
  }) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.58),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  // How spend% compares to how far through the period we are - lets a user
  // tell "60% spent, day 5 of 30" (way ahead of pace) apart from "60% spent,
  // day 25 of 30" (fine), which the raw percentage alone can't show.
  Widget _buildPaceLine(BuildContext context, double percentage) {
    final totalDays = budget.endDate.difference(budget.startDate).inDays;
    if (totalDays <= 0) return const SizedBox.shrink();

    final now = DateTime.now();
    final daysLeft = budget.endDate.difference(now).inDays;
    if (daysLeft < 0) return const SizedBox.shrink();

    final daysElapsed =
        now.difference(budget.startDate).inDays.clamp(0, totalDays);
    final expectedPercentage = daysElapsed / totalDays * 100;
    final isPacingFast = percentage > expectedPercentage + 10;

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        '$daysLeft day${daysLeft == 1 ? '' : 's'} left'
        '${isPacingFast ? ' · spending faster than pace' : ''}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: isPacingFast ? FontWeight.w600 : FontWeight.normal,
          color: isPacingFast
              ? AppColors.warning
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}
