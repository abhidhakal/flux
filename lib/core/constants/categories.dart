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
    'Food & Dining': 0xFF333333,
    'Transportation': 0xFF444444,
    'Entertainment': 0xFF555555,
    'Shopping': 0xFF666666,
    'Bills & Utilities': 0xFF777777,
    'Healthcare': 0xFF888888,
    'Education': 0xFF999999,
    'Housing': 0xFFAAAAAA,
    'Insurance': 0xFFBBBBBB,
    'Personal Care': 0xFFCCCCCC,
    'Travel': 0xFFDDDDDD,
    'Gifts': 0xFF666666,
    'Other': 0xFF888888,
    'Salary': 0xFF555555,
    'Freelance': 0xFF777777,
    'Investment': 0xFF999999,
    'Business': 0xFFBBBBBB,
    'Other Income': 0xFF666666,
  };

  // Get color for category
  static int getColor(String category) {
    return categoryColors[category] ?? 0xFF888888;
  }
}
