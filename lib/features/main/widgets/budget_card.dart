import 'package:flutter/material.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/models/budget_model.dart';
import '../../../core/services/currency_service.dart';
import '../../budget/screens/edit_budget_screen.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_icon_badge.dart';
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
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = muted
        ? colorScheme.onSurface.withValues(alpha: 0.5)
        : isOverBudget
            ? AppColors.error
            : percentage > 80
                ? AppColors.warning
                : AppColors.primary;
    final mutedText = colorScheme.onSurface.withValues(alpha: 0.58);

    return AppCard(
      onTap: () => EditBudgetScreen.showEditBudgetSheet(context, budget),
      onLongPress: onDelete,
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 16),
      radius: 26,
      subtle: muted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIconBadge(
                icon: muted
                    ? LucideIcons.pauseCircle
                    : isOverBudget
                        ? LucideIcons.alertTriangle
                        : percentage > 80
                            ? LucideIcons.trendingUp
                            : LucideIcons.coins,
                color: statusColor,
                size: AppIconBadgeSize.medium,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.25,
                        color: colorScheme.onSurface
                            .withValues(alpha: muted ? 0.65 : 1),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${budget.category}  ·  ${_periodLabel(budget.period.name)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: mutedText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                LucideIcons.chevronRight,
                size: 19,
                color: colorScheme.onSurface.withValues(alpha: 0.32),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _amountSummary(
                  context,
                  label: 'Spent',
                  value: CurrencyService().formatAmount(spent),
                  color: muted ? statusColor : colorScheme.onSurface,
                ),
              ),
              Expanded(
                child: _amountSummary(
                  context,
                  label: 'Limit',
                  value: CurrencyService().formatAmount(budget.totalAvailable),
                  color: muted ? statusColor : colorScheme.onSurface,
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
              minHeight: 9,
              backgroundColor: colorScheme.onSurface.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 9),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${percentage.toStringAsFixed(1)}% used',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: statusColor,
                ),
              ),
              Text(
                isOverBudget
                    ? 'Over by ${CurrencyService().formatAmount(-budget.remaining)}'
                    : '${CurrencyService().formatAmount(budget.remaining)} left',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: muted
                      ? statusColor
                      : isOverBudget
                          ? AppColors.error
                          : AppColors.success,
                ),
              ),
            ],
          ),
          if (!muted && !isOverBudget) _buildPaceLine(context, percentage),
          if (!muted &&
              (budget.hasWeeklyTarget ||
                  budget.hasTemporaryAdjustment ||
                  budget.hasRollover)) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (budget.hasWeeklyTarget)
                  _metadataChip(
                    'Weekly ${CurrencyService().formatAmount(budget.weeklyTarget)}',
                  ),
                if (budget.hasTemporaryAdjustment)
                  _metadataChip(
                    '${budget.temporaryAdjustment >= 0 ? '+' : '-'}${CurrencyService().formatAmount(budget.temporaryAdjustment.abs())} adjustment',
                  ),
                if (budget.hasRollover)
                  _metadataChip(
                    '${CurrencyService().formatAmount(budget.rolloverAmount)} rollover',
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _metadataChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
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
            fontWeight: FontWeight.w600,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

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
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        '$daysLeft day${daysLeft == 1 ? '' : 's'} left'
        '${isPacingFast ? ' • spending faster than pace' : ''}',
        style: TextStyle(
          fontSize: 11,
          fontWeight: isPacingFast ? FontWeight.w700 : FontWeight.w500,
          color: isPacingFast
              ? AppColors.warning
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.52),
        ),
      ),
    );
  }
}
