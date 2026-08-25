import 'package:flutter/material.dart';
import '../../core/constants/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Shared top-of-page surface for primary navigation pages.
///
/// This is intentionally a body widget rather than an AppBar so the page
/// title, actions, status-bar area, and curved surface stay visually unified.
class PremiumPageHero extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? eyebrow;
  final FontWeight titleWeight;
  final List<Widget> actions;
  final bool showBackButton;

  const PremiumPageHero({
    super.key,
    required this.title,
    required this.subtitle,
    this.eyebrow,
    this.titleWeight = FontWeight.w800,
    this.actions = const [],
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 24),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(38),
          bottomRight: Radius.circular(38),
        ),
        boxShadow: [
          BoxShadow(
              color: Color(0x260079DC), blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
      child: SafeArea(
        top: true,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 16, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showBackButton) ...[
                IconButton(
                  tooltip: 'Back',
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(
                    LucideIcons.arrowLeft,
                    color: Colors.white,
                    size: 20,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.14),
                    fixedSize: const Size(44, 44),
                    shape: const CircleBorder(),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (eyebrow != null) ...[
                      Text(
                        eyebrow!.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.68),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        letterSpacing: -0.8,
                        height: 1.05,
                      ).copyWith(fontWeight: titleWeight),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}

class PremiumPageHeroAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const PremiumPageHeroAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.14),
        fixedSize: const Size(44, 44),
        shape: const CircleBorder(),
      ),
    );
  }
}
