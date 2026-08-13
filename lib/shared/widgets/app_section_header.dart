import 'package:flutter/material.dart';
import '../../core/constants/app_theme.dart';

/// Consistent title/subtitle treatment for grouped screen sections.
class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTheme.sectionTitleStyle(context)),
        if (subtitle != null)
          Text(subtitle!, style: AppTheme.sectionSubtitleStyle(context)),
      ],
    );

    if (trailing == null) return header;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: header),
        const SizedBox(width: AppTheme.spacing12),
        trailing!,
      ],
    );
  }
}
