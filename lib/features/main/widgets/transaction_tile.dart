import 'package:flutter/material.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/services/currency_service.dart';
import '../../../shared/widgets/app_icon_badge.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class TransactionTile extends StatelessWidget {
  final Transaction item;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool showCard;

  const TransactionTile({
    super.key,
    required this.item,
    required this.onTap,
    required this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.showCard = true,
  });

  static String _formatTime(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final title = item.title;
    final subtitle =
        item.description.isNotEmpty ? item.description : item.category;
    final amount = item.amount;
    final date = item.date;
    final isIncome = item.isIncome;
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = isIncome ? AppColors.success : AppColors.error;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: showCard ? const EdgeInsets.only(bottom: 10) : EdgeInsets.zero,
        padding: showCard
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 14)
            : const EdgeInsets.symmetric(vertical: 12),
        decoration: !showCard
            ? null
            : BoxDecoration(
                color: AppTheme.cardSurface(context),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : colorScheme.outline.withValues(alpha: 0.10),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
        child: Row(
          children: [
            // Leading icon / checkbox
            if (isSelectionMode)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color:
                          isSelected ? AppColors.primary : colorScheme.outline,
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(LucideIcons.check,
                          size: 14, color: Colors.white)
                      : null,
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: AppIconBadge(
                  icon: isIncome ? LucideIcons.plus : LucideIcons.minus,
                  color: accentColor,
                  size: AppIconBadgeSize.large,
                ),
              ),

            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Amount + time
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}${CurrencyService().formatAmount(amount)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTime(date),
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
