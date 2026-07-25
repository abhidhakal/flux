import 'package:flutter/material.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/models/budget_model.dart';
import '../../../core/services/currency_service.dart';
import '../../budget/screens/edit_budget_screen.dart';

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
    final total = budget.totalAvailable;
    final percentage = budget.progressPercentage;
    final isOverBudget = budget.isOverBudget;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine card color based on budget status
    Color cardColor;
    Color borderColor;
    if (muted) {
      cardColor = colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);
      borderColor = colorScheme.outline.withValues(alpha: 0.35);
    } else if (spent <= 0) {
      cardColor = AppColors.primary.withValues(alpha: 0.06);
      borderColor = AppColors.primary.withValues(alpha: 0.28);
    } else if (isOverBudget) {
      cardColor = AppColors.error.withValues(alpha: 0.08);
      borderColor = AppColors.error.withValues(alpha: 0.35);
    } else if (percentage > 80) {
      cardColor = AppColors.warning.withValues(alpha: 0.08);
      borderColor = AppColors.warning.withValues(alpha: 0.3);
    } else {
      cardColor = AppTheme.cardSurface(context);
      borderColor = colorScheme.outline.withValues(alpha: 0.12);
    }

    return InkWell(
      onTap: () => EditBudgetScreen.showEditBudgetSheet(context, budget),
      borderRadius: BorderRadius.circular(AppTheme.radius16),
      child: Card(
        margin: EdgeInsets.zero, // Card margin handled by ListView separator
        elevation: 0,
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius20),
          side: BorderSide(
            color: borderColor,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with icon and title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacing8),
                    decoration: BoxDecoration(
                      color: muted
                          ? colorScheme.outline.withValues(alpha: 0.15)
                          : isOverBudget
                              ? AppColors.error.withValues(alpha: 0.1)
                              : percentage > 80
                                  ? AppColors.warning.withValues(alpha: 0.1)
                                  : AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radius8),
                    ),
                    child: Icon(
                      muted
                          ? Icons.pause_circle_filled_rounded
                          : isOverBudget
                              ? Icons.warning
                              : percentage > 80
                                  ? Icons.trending_up_rounded
                                  : Icons.wallet_rounded,
                      color: muted
                          ? colorScheme.onSurface.withValues(alpha: 0.65)
                          : isOverBudget
                              ? AppColors.error
                              : percentage > 80
                                  ? AppColors.warning
                                  : AppColors.primary,
                      size: 20,
                    ),
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
                              '${budget.category} • ${budget.period.name.toUpperCase()}',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                            if (!budget.isActive) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color:
                                      colorScheme.outline.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Inactive',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.75),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon:
                        const Icon(Icons.delete_outline, color: AppColors.error),
                    tooltip: 'Delete Budget',
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing8),
              // Amount row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${CurrencyService().formatAmount(spent)} / ${CurrencyService().formatAmount(total)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: muted
                          ? colorScheme.onSurface.withValues(alpha: 0.7)
                          : isOverBudget
                              ? AppColors.error
                              : colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: (percentage / 100).clamp(0.0, 1.0),
                backgroundColor: colorScheme.outline.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  muted
                      ? colorScheme.onSurface.withValues(alpha: 0.3)
                      : isOverBudget
                          ? AppColors.error
                          : AppColors.primary,
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
                  Text(
                    '${CurrencyService().formatAmount(total - spent)} remaining',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              if (isOverBudget && !muted)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Over budget by ${CurrencyService().formatAmount(spent - total)}',
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
        ),
      ),
    );
  }
}
