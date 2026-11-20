import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_theme.dart';

/// Stacked mini product cards (balance, budget, goal) used as the hero on the
/// welcome screen and first onboarding page. [t] drives the entrance (0→1).
class FluxPreview extends StatelessWidget {
  final Animation<double> t;
  const FluxPreview({super.key, required this.t});

  Widget _stagger(double start, Widget child, {double dy = 24, double rot = 0}) {
    final a = CurvedAnimation(
      parent: t,
      curve: Interval(start, math.min(start + 0.5, 1), curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: a,
      builder: (_, c) => Opacity(
        opacity: a.value,
        child: Transform.translate(
          offset: Offset(0, dy * (1 - a.value)),
          child: Transform.rotate(angle: rot, child: c),
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 268,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 36,
            top: 0,
            child: _stagger(0.0, const _BalanceCard(), rot: -0.03),
          ),
          Positioned(
            right: 0,
            top: 150,
            width: 200,
            child: _stagger(0.2, const _BudgetCard(), rot: 0.025),
          ),
          Positioned(
            left: 12,
            top: 186,
            child: _stagger(0.35, const _GoalChip(), rot: -0.02),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _card(Color color) => BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [
        BoxShadow(color: Color(0x40000000), blurRadius: 30, offset: Offset(0, 14)),
      ],
    );

class _BalanceCard extends StatelessWidget {
  const _BalanceCard();

  @override
  Widget build(BuildContext context) {
    const bars = [0.35, 0.55, 0.42, 0.7, 0.5, 0.85, 0.62];
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: _card(AppColors.primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('This month',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          const Text('\$2,418.60',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1)),
          const SizedBox(height: 14),
          SizedBox(
            height: 44,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < bars.length; i++) ...[
                  Expanded(
                    child: FractionallySizedBox(
                      heightFactor: bars[i],
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white
                              .withValues(alpha: i == 5 ? 1 : 0.32),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                  if (i != bars.length - 1) const SizedBox(width: 6),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _card(Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.shoppingBasket, size: 16, color: AppColors.tertiary),
              SizedBox(width: 6),
              Text('Groceries',
                  style: TextStyle(
                      color: AppColors.tertiary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
              Spacer(),
              Text('72%',
                  style: TextStyle(
                      color: AppColors.success,
                      fontSize: 13,
                      fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: const LinearProgressIndicator(
              value: 0.72,
              minHeight: 7,
              backgroundColor: Color(0xFFE8EEF5),
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 8),
          const Text('\$108 left this week',
              style: TextStyle(color: Color(0xFF66768A), fontSize: 12)),
        ],
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  const _GoalChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: _card(AppColors.tertiaryLight),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.target, size: 16, color: AppColors.warningLight),
          SizedBox(width: 8),
          Text('Japan trip · 64%',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
