import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AppCategories {
  // Core expense categories
  static const List<String> expenseCategories = [
    'Food & Dining',
    'Transportation',
    'Entertainment',
    'Shopping',
    'Bills & Utilities',
    'Healthcare',
    'Education',
    'Housing',
    'Insurance',
    'Personal Care',
    'Travel',
    'Gifts',
    'Other',
  ];

  // Income categories
  static const List<String> incomeCategories = [
    'Salary',
    'Freelance',
    'Investment',
    'Business',
    'Gifts',
    'Other Income',
  ];

  // All categories combined
  static List<String> get allCategories => [
        ...expenseCategories,
        ...incomeCategories,
      ];

  /// Line icon per category, the same set the home-screen widgets use.
  static IconData iconFor(String category) => switch (category) {
        'Food & Dining' => LucideIcons.utensils,
        'Transportation' => LucideIcons.car,
        'Entertainment' => LucideIcons.clapperboard,
        'Shopping' => LucideIcons.shoppingBag,
        'Bills & Utilities' => LucideIcons.zap,
        'Healthcare' => LucideIcons.heartPulse,
        'Education' => LucideIcons.graduationCap,
        'Housing' => LucideIcons.house,
        'Insurance' => LucideIcons.shield,
        'Personal Care' => LucideIcons.sparkles,
        'Travel' => LucideIcons.plane,
        'Gifts' => LucideIcons.gift,
        'Salary' => LucideIcons.wallet,
        'Freelance' => LucideIcons.briefcase,
        'Investment' => LucideIcons.trendingUp,
        'Business' => LucideIcons.building2,
        'Other Income' => LucideIcons.banknote,
        _ => LucideIcons.tag,
      };

}
