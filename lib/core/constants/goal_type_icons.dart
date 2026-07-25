import 'package:flutter/material.dart';
import '../models/goal_model.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Icon shown for each [GoalType], shared across the goal card, create, and
/// edit screens so they can't visually drift from each other.
extension GoalTypeIcon on GoalType {
  IconData get icon {
    switch (this) {
      case GoalType.savings:
        return LucideIcons.piggyBank;
      case GoalType.debt:
        return LucideIcons.creditCard;
      case GoalType.investment:
        return LucideIcons.trendingUp;
      case GoalType.emergency:
        return LucideIcons.heartPulse;
      case GoalType.vacation:
        return LucideIcons.plane;
      case GoalType.home:
        return LucideIcons.home;
      case GoalType.education:
        return LucideIcons.school;
      case GoalType.other:
        return LucideIcons.flag;
    }
  }
}
