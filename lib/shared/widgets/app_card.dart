import 'package:flutter/material.dart';

import '../../core/constants/app_theme.dart';

/// The standard surface container for feature screens.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? tint;
  final bool subtle;
  final double? radius;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool emphasizeTint;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTheme.spacing16),
    this.tint,
    this.subtle = false,
    this.radius,
    this.onTap,
    this.onLongPress,
    this.emphasizeTint = false,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = tint == null
        ? AppTheme.surfaceDecoration(
            context,
            radius: radius ?? AppTheme.cardRadius,
            subtle: subtle,
          )
        : AppTheme.tintedSurfaceDecoration(
            context,
            tint: tint!,
            radius: radius ?? AppTheme.cardRadius,
          );

    final resolvedDecoration = tint != null && emphasizeTint
        ? BoxDecoration(
            color: tint!.withValues(
              alpha:
                  Theme.of(context).brightness == Brightness.dark ? 0.28 : 0.16,
            ),
            borderRadius: BorderRadius.circular(radius ?? AppTheme.cardRadius),
          )
        : decoration;

    final content = Container(
      width: double.infinity,
      padding: padding,
      decoration: resolvedDecoration,
      child: child,
    );

    if (onTap == null && onLongPress == null) {
      return content;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius ?? AppTheme.cardRadius),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: content,
      ),
    );
  }
}
