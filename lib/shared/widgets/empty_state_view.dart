import 'package:flutter/material.dart';

/// Shared icon → title → subtitle → optional CTA layout used for both
/// empty states and error states across list/dashboard screens.
class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final double iconSize;
  final String title;
  final double titleFontSize;
  final String? subtitle;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final ButtonStyle? actionStyle;
  final double spacingBeforeAction;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    this.iconColor,
    this.iconSize = 64,
    this.titleFontSize = 20,
    this.subtitle,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.actionStyle,
    this.spacingBeforeAction = 16,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              size: iconSize, color: iconColor ?? colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            SizedBox(height: spacingBeforeAction),
            actionIcon != null
                ? ElevatedButton.icon(
                    onPressed: onAction,
                    icon: Icon(actionIcon),
                    label: Text(actionLabel!),
                    style: actionStyle,
                  )
                : ElevatedButton(
                    onPressed: onAction,
                    style: actionStyle,
                    child: Text(actionLabel!),
                  ),
          ],
        ],
      ),
    );
  }
}
