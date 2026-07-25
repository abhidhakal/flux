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

  // Category icons mapping
  static const Map<String, String> categoryIcons = {
    'Food & Dining': '🍽️',
    'Transportation': '🚗',
    'Entertainment': '🎬',
    'Shopping': '🛍️',
    'Bills & Utilities': '⚡',
    'Healthcare': '🏥',
    'Education': '📚',
    'Housing': '🏠',
    'Insurance': '🛡️',
    'Personal Care': '💄',
    'Travel': '✈️',
    'Gifts': '🎁',
    'Other': '📝',
    'Salary': '💰',
    'Freelance': '💼',
    'Investment': '📈',
    'Business': '🏢',
    'Other Income': '💵',
  };

  // Category colors mapping
  static const Map<String, int> categoryColors = {
    'Food & Dining': 0xFFFF6B6B,
    'Transportation': 0xFF4ECDC4,
    'Entertainment': 0xFF45B7D1,
    'Shopping': 0xFFFF9500,
    'Bills & Utilities': 0xFF34C759,
    'Healthcare': 0xFFFF3B30,
    'Education': 0xFF5856D6,
    'Housing': 0xFF007AFF,
    'Insurance': 0xFFAF52DE,
    'Personal Care': 0xFFFF2D92,
    'Travel': 0xFF00C7BE,
    'Gifts': 0xFFFF9500,
    'Other': 0xFF8E8E93,
    'Salary': 0xFF34C759,
    'Freelance': 0xFF007AFF,
    'Investment': 0xFF5856D6,
    'Business': 0xFFAF52DE,
    'Other Income': 0xFF34C759,
  };

  // Get icon for category
  static String getIcon(String category) {
    return categoryIcons[category] ?? '📝';
  }

  // Get color for category
  static int getColor(String category) {
    return categoryColors[category] ?? 0xFF8E8E93;
  }

  // Check if category is expense
  static bool isExpenseCategory(String category) {
    return expenseCategories.contains(category);
  }

  // Check if category is income
  static bool isIncomeCategory(String category) {
    return incomeCategories.contains(category);
  }
}
