import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_theme.dart';

class SkeletonComponents {
  // Theme-aware shimmer configuration
  static Widget shimmerWrapper({
    required Widget child,
    required BuildContext context,
    Color? baseColor,
    Color? highlightColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: baseColor ??
          (isDark
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
              : AppColors.lightTextTertiary.withValues(alpha: 0.3)),
      highlightColor: highlightColor ??
          (isDark
              ? colorScheme.surface.withValues(alpha: 0.5)
              : AppColors.lightTextTertiary.withValues(alpha: 0.1)),
      period: const Duration(milliseconds: 1500),
      child: child,
    );
  }

  // Skeleton for text lines
  static Widget textLine({
    double? width,
    double height = 16,
    double borderRadius = 4,
    BuildContext? context, // Make context optional
  }) {
    return Builder(
      builder: (ctx) {
        final actualContext = context ?? ctx;
        final colorScheme = Theme.of(actualContext).colorScheme;

        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: colorScheme.surface, // Use theme-aware color
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        );
      },
    );
  }

  // Skeleton for circular elements (avatars, icons)
  static Widget circle({
    double size = 40,
    required BuildContext context,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        shape: BoxShape.circle,
      ),
    );
  }

  // Skeleton for rectangular elements
  static Widget rectangle({
    double? width,
    double? height,
    double borderRadius = 8,
    required BuildContext context,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  // Skeleton for cards
  static Widget card({
    double? width,
    double height = 120,
    double borderRadius = 12,
    EdgeInsets padding = const EdgeInsets.all(16),
    List<Widget>? children,
    required BuildContext context,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    // An empty card is a plain surface box, invisible on the page
    // background, so it shimmers as a solid placeholder block instead.
    if (children == null) {
      return shimmerWrapper(
        context: context,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.hardEdge,
      padding: padding,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  // Skeleton for transaction list items
  static Widget transactionListItem({required BuildContext context}) {
    return shimmerWrapper(
      context: context,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon placeholder
            circle(size: 40, context: context),
            const SizedBox(width: 12),
            // Content placeholder
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  textLine(
                      width: double.infinity, height: 16, context: context),
                  const SizedBox(height: 8),
                  textLine(width: 120, height: 14, context: context),
                ],
              ),
            ),
            // Amount placeholder
            textLine(width: 80, height: 16, context: context),
          ],
        ),
      ),
    );
  }

  // Skeleton for goal cards
  static Widget goalCard({required BuildContext context}) {
    return shimmerWrapper(
      context: context,
      child: card(
        height: 140,
        context: context,
        children: [
          // Header
          Row(
            children: [
              circle(size: 32, context: context),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    textLine(width: 120, height: 16, context: context),
                    const SizedBox(height: 4),
                    textLine(width: 80, height: 12, context: context),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          textLine(width: double.infinity, height: 8, context: context),
          const SizedBox(height: 8),
          // Progress text
          textLine(width: 100, height: 12, context: context),
        ],
      ),
    );
  }

  // Skeleton for budget cards
  static Widget budgetCard({required BuildContext context}) {
    return shimmerWrapper(
      context: context,
      child: card(
        height: 100,
        context: context,
        children: [
          // Category and amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              textLine(width: 100, height: 16, context: context),
              textLine(width: 80, height: 16, context: context),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          textLine(width: double.infinity, height: 8, context: context),
          const SizedBox(height: 8),
          // Progress details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              textLine(width: 60, height: 12, context: context),
              textLine(width: 80, height: 12, context: context),
            ],
          ),
        ],
      ),
    );
  }

  // Skeleton for dashboard stats
  static Widget dashboardStat({required BuildContext context}) {
    return shimmerWrapper(
      context: context,
      child: card(
        height: 100,
        context: context,
        children: [
          // Icon and title
          Row(
            children: [
              circle(size: 24, context: context),
              const SizedBox(width: 8),
              textLine(width: 80, height: 14, context: context),
            ],
          ),
          const SizedBox(height: 12),
          // Amount
          textLine(width: 120, height: 20, context: context),
          const SizedBox(height: 4),
          // Change indicator
          textLine(width: 60, height: 12, context: context),
        ],
      ),
    );
  }

  // Skeleton for chart
  static Widget chart({double height = 200, required BuildContext context}) {
    return shimmerWrapper(
      context: context,
      child: card(
        height: height,
        context: context,
        children: [
          // Chart title
          textLine(width: 120, height: 16, context: context),
          const SizedBox(height: 16),
          // Chart area
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Skeleton for list items
  static Widget listItem({
    double height = 60,
    bool showIcon = true,
    required BuildContext context,
  }) {
    return shimmerWrapper(
      context: context,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (showIcon) ...[
              circle(size: 32, context: context),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  textLine(
                      width: double.infinity, height: 16, context: context),
                  const SizedBox(height: 6),
                  textLine(width: 150, height: 12, context: context),
                ],
              ),
            ),
            textLine(width: 60, height: 14, context: context),
          ],
        ),
      ),
    );
  }

  // Skeleton for profile section
  static Widget profileSection({required BuildContext context}) {
    return shimmerWrapper(
      context: context,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile picture and name
            Row(
              children: [
                circle(size: 60, context: context),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      textLine(width: 120, height: 18, context: context),
                      const SizedBox(height: 4),
                      textLine(width: 100, height: 14, context: context),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    textLine(width: 40, height: 16, context: context),
                    const SizedBox(height: 4),
                    textLine(width: 60, height: 12, context: context),
                  ],
                ),
                Column(
                  children: [
                    textLine(width: 40, height: 16, context: context),
                    const SizedBox(height: 4),
                    textLine(width: 60, height: 12, context: context),
                  ],
                ),
                Column(
                  children: [
                    textLine(width: 40, height: 16, context: context),
                    const SizedBox(height: 4),
                    textLine(width: 60, height: 12, context: context),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Skeleton for form fields
  static Widget formField({
    double height = 56,
    String? label,
    required BuildContext context,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          textLine(width: 80, height: 14, context: context),
          const SizedBox(height: 8),
        ],
        shimmerWrapper(
          context: context,
          child: rectangle(
            width: double.infinity,
            height: height,
            borderRadius: 12,
            context: context,
          ),
        ),
      ],
    );
  }

  // Skeleton for buttons
  static Widget button({
    double width = double.infinity,
    double height = 48,
    required BuildContext context,
  }) {
    return shimmerWrapper(
      context: context,
      child: rectangle(
        width: width,
        height: height,
        borderRadius: 12,
        context: context,
      ),
    );
  }

  // Skeleton for notification cards
  static Widget notificationCard({required BuildContext context}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: shimmerWrapper(
        context: context,
        child: card(
          height: 80,
          context: context,
          children: [
            Row(
              children: [
                circle(size: 32, context: context),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      textLine(
                          width: double.infinity, height: 16, context: context),
                      const SizedBox(height: 4),
                      textLine(width: 200, height: 14, context: context),
                      const SizedBox(height: 4),
                      textLine(width: 80, height: 12, context: context),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Skeleton for profile header
  static Widget profileHeader({required BuildContext context}) {
    return shimmerWrapper(
      context: context,
      child: card(
        height: 200,
        context: context,
        children: [
          Center(child: circle(size: 80, context: context)),
          const SizedBox(height: 16),
          Center(child: textLine(width: 120, height: 20, context: context)),
          const SizedBox(height: 8),
          Center(child: textLine(width: 160, height: 16, context: context)),
          const SizedBox(height: 12),
          Center(child: textLine(width: 100, height: 14, context: context)),
        ],
      ),
    );
  }
}
