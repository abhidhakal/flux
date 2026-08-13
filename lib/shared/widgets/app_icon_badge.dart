import 'package:flutter/material.dart';

enum AppIconBadgeSize { small, medium, large }

class AppIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final AppIconBadgeSize size;

  const AppIconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = AppIconBadgeSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    final dimensions = switch (size) {
      AppIconBadgeSize.small => (box: 32.0, icon: 16.0, radius: 10.0),
      AppIconBadgeSize.medium => (box: 40.0, icon: 19.0, radius: 12.0),
      AppIconBadgeSize.large => (box: 48.0, icon: 23.0, radius: 14.0),
    };

    return SizedBox.square(
      dimension: dimensions.box,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(dimensions.radius),
        ),
        child: Icon(icon, color: color, size: dimensions.icon),
      ),
    );
  }
}
