import 'package:flutter/material.dart';
import '../../core/constants/app_theme.dart';

/// Shared "icon chip + label + value" stat card used across
/// budgets/goals/analytics/profile summary rows.
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? accentColor;
  final Axis direction;
  final bool bordered;
  final double radius;
  final EdgeInsetsGeometry padding;
  final bool valueFirst;
  final bool centered;
  final double valueFontSize;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.accentColor,
    this.direction = Axis.vertical,
    this.bordered = false,
    this.radius = 20,
    this.padding = const EdgeInsets.all(16),
    this.valueFirst = false,
    this.centered = false,
    this.valueFontSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = accentColor ?? colorScheme.primary;
    final decoration =
        AppTheme.surfaceDecoration(context, radius: radius, subtle: !bordered);

    final iconChip = icon == null
        ? null
        : Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon,
                color: color, size: direction == Axis.horizontal ? 18 : 16),
          );

    final labelText = Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface.withOpacity(0.65),
      ),
    );

    final valueText = Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: direction == Axis.horizontal ? 14 : valueFontSize,
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
      ),
    );

    final textLines = valueFirst
        ? [valueText, const SizedBox(height: 4), labelText]
        : [labelText, const SizedBox(height: 4), valueText];

    final content = direction == Axis.horizontal
        ? Row(
            children: [
              if (iconChip != null) ...[iconChip, const SizedBox(width: 10)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: textLines,
                ),
              ),
            ],
          )
        : Column(
            crossAxisAlignment:
                centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              if (iconChip != null) ...[iconChip, const SizedBox(height: 12)],
              ...textLines,
            ],
          );

    return Container(padding: padding, decoration: decoration, child: content);
  }
}
