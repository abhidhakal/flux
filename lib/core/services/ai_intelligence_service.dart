import '../models/transaction_model.dart';
import 'currency_service.dart';

class AIIntelligenceService {
  // Smart categorization based on transaction title and description
  String categorizeTransaction(String title, String description) {
    final text = '${title.toLowerCase()} ${description.toLowerCase()}';
    
    // Food & Dining patterns
    if (_matchesPattern(text, [
      'restaurant', 'food', 'meal', 'dinner', 'lunch', 'breakfast',
      'cafe', 'coffee', 'pizza', 'burger', 'sushi', 'mcdonalds',
      'starbucks', 'uber eats', 'doordash', 'grubhub', 'delivery'
    ])) {
      return 'Food & Dining';
    }
    
    // Transportation patterns
    if (_matchesPattern(text, [
      'uber', 'lyft', 'taxi', 'gas', 'fuel', 'parking', 'metro',
      'bus', 'train', 'subway', 'car', 'auto', 'transportation',
      'shell', 'exxon', 'bp', 'chevron', 'toll', 'parking'
    ])) {
      return 'Transportation';
    }
    
    // Entertainment patterns
    if (_matchesPattern(text, [
      'netflix', 'spotify', 'hulu', 'disney', 'amazon prime',
      'movie', 'cinema', 'theater', 'concert', 'show', 'game',
      'entertainment', 'fun', 'amusement', 'park', 'museum'
    ])) {
      return 'Entertainment';
    }
    
    // Shopping patterns
    if (_matchesPattern(text, [
      'amazon', 'walmart', 'target', 'costco', 'best buy',
      'shopping', 'store', 'mall', 'clothing', 'shoes', 'apparel',
      'electronics', 'furniture', 'home', 'decor', 'fashion'
    ])) {
      return 'Shopping';
    }
    
    // Utilities patterns
    if (_matchesPattern(text, [
      'electric', 'gas', 'water', 'internet', 'wifi', 'phone',
      'utility', 'bill', 'power', 'energy', 'at&t', 'verizon',
      'comcast', 'spectrum', 'cable', 'electricity'
    ])) {
      return 'Utilities';
    }
    
    // Healthcare patterns
    if (_matchesPattern(text, [
      'doctor', 'hospital', 'medical', 'pharmacy', 'cvs',
      'walgreens', 'health', 'dental', 'vision', 'insurance',
      'medicine', 'prescription', 'clinic', 'physician'
    ])) {
      return 'Healthcare';
    }
    
    // Education patterns
    if (_matchesPattern(text, [
      'school', 'university', 'college', 'course', 'class',
      'education', 'tuition', 'books', 'textbook', 'student',
      'learning', 'training', 'workshop', 'seminar'
    ])) {
      return 'Education';
    }
    
    // Housing patterns
    if (_matchesPattern(text, [
      'rent', 'mortgage', 'apartment', 'house', 'home',
      'real estate', 'property', 'landlord', 'maintenance',
      'repair', 'renovation', 'furniture', 'appliance'
    ])) {
      return 'Housing';
    }
    
    // Insurance patterns
    if (_matchesPattern(text, [
      'insurance', 'coverage', 'policy', 'premium', 'claim',
      'auto insurance', 'home insurance', 'life insurance',
      'health insurance', 'geico', 'state farm', 'allstate'
    ])) {
      return 'Insurance';
    }
    
    // Personal Care patterns
    if (_matchesPattern(text, [
      'salon', 'spa', 'beauty', 'cosmetic', 'makeup',
      'haircut', 'manicure', 'pedicure', 'massage', 'gym',
      'fitness', 'workout', 'personal care', 'wellness'
    ])) {
      return 'Personal Care';
    }
    
    // Travel patterns
    if (_matchesPattern(text, [
      'hotel', 'flight', 'airline', 'airport', 'vacation',
      'travel', 'trip', 'booking', 'reservation', 'airbnb',
      'expedia', 'booking.com', 'hotels.com', 'tourism'
    ])) {
      return 'Travel';
    }
    
    // Gifts patterns
    if (_matchesPattern(text, [
      'gift', 'present', 'birthday', 'anniversary', 'wedding',
      'celebration', 'party', 'donation', 'charity', 'fundraiser'
    ])) {
      return 'Gifts';
    }
    
    // Income patterns
    if (_matchesPattern(text, [
      'salary', 'paycheck', 'income', 'deposit', 'transfer',
      'payment', 'reimbursement', 'refund', 'bonus', 'commission'
    ])) {
      return 'Salary';
    }
    
    // Default to "Other" if no pattern matches
    return 'Other';
  }

  // Analyze spending patterns and provide insights
  Map<String, dynamic> analyzeSpendingPatterns(List<Transaction> transactions) {
    if (transactions.isEmpty) {
      return {
        'totalSpent': 0.0,
        'averageSpent': 0.0,
        'topCategories': [],
        'spendingTrend': 'stable',
        'insights': ['No transactions to analyze'],
        'recommendations': ['Start tracking your expenses to get insights'],
      };
    }

    final expenses = transactions.where((t) => t.isExpense).toList();
    final totalSpent = expenses.fold(0.0, (sum, t) => sum + t.amount);
    final averageSpent = totalSpent / expenses.length;

    // Category analysis
    final categoryTotals = <String, double>{};
    for (final transaction in expenses) {
      categoryTotals[transaction.category] = 
          (categoryTotals[transaction.category] ?? 0) + transaction.amount;
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final topCategories = sortedCategories.take(3).map((e) => {
      'category': e.key,
      'amount': e.value,
      'percentage': (e.value / totalSpent * 100).toStringAsFixed(1),
    }).toList();

    // Spending trend analysis
    final recentTransactions = expenses.where((t) => 
        DateTime.now().difference(t.date).inDays <= 30).toList();
    final olderTransactions = expenses.where((t) => 
        DateTime.now().difference(t.date).inDays > 30).toList();

    final recentTotal = recentTransactions.fold(0.0, (sum, t) => sum + t.amount);
    final olderTotal = olderTransactions.fold(0.0, (sum, t) => sum + t.amount);

    String spendingTrend = 'stable';
    if (recentTotal > olderTotal * 1.2) {
      spendingTrend = 'increasing';
    } else if (recentTotal < olderTotal * 0.8) {
      spendingTrend = 'decreasing';
    }

    // Generate insights
    final insights = <String>[];
    if (topCategories.isNotEmpty) {
      final topCategory = topCategories.first;
      insights.add('Your biggest expense is ${topCategory['category']} (${topCategory['percentage']}% of total)');
    }
    
    if (spendingTrend == 'increasing') {
      insights.add('Your spending has increased recently');
    } else if (spendingTrend == 'decreasing') {
      insights.add('Great job! Your spending has decreased recently');
    }

    if (averageSpent > 100) {
      insights.add('Your average transaction is ${CurrencyService().formatAmount(averageSpent).replaceAll('.00', '')}');
    }

    // Generate recommendations
    final recommendations = <String>[];
    if (spendingTrend == 'increasing') {
      recommendations.add('Consider setting spending limits for high-expense categories');
    }
    
    if (topCategories.isNotEmpty && double.parse(topCategories.first['percentage'] as String) > 40) {
      recommendations.add('Try to diversify your spending across different categories');
    }

    recommendations.add('Set up budgets for your top spending categories');
    recommendations.add('Review your transactions weekly to stay on track');

    return {
      'totalSpent': totalSpent,
      'averageSpent': averageSpent,
      'topCategories': topCategories,
      'spendingTrend': spendingTrend,
      'insights': insights,
      'recommendations': recommendations,
    };
  }

  // Generate smart budget recommendations
  List<BudgetRecommendation> generateBudgetRecommendations(
    List<Transaction> transactions,
    double monthlyIncome,
  ) {
    final analysis = analyzeSpendingPatterns(transactions);
    final recommendations = <BudgetRecommendation>[];

    // 50/30/20 rule recommendations
    final needs = monthlyIncome * 0.5;
    final wants = monthlyIncome * 0.3;
    final savings = monthlyIncome * 0.2;

    recommendations.add(BudgetRecommendation(
      name: 'Essential Needs',
      amount: needs,
      category: 'Housing',
      description: '50% of income for housing, utilities, food, and basic needs',
      priority: 'High',
    ));

    recommendations.add(BudgetRecommendation(
      name: 'Lifestyle & Wants',
      amount: wants,
      category: 'Entertainment',
      description: '30% of income for entertainment, shopping, and personal expenses',
      priority: 'Medium',
    ));

    recommendations.add(BudgetRecommendation(
      name: 'Savings & Goals',
      amount: savings,
      category: 'Investment',
      description: '20% of income for savings, investments, and financial goals',
      priority: 'High',
    ));

    // Category-specific recommendations based on spending patterns
    if (analysis['topCategories'] != null) {
      for (final category in analysis['topCategories'] as List<Map<String, dynamic>>) {
        final categoryName = category['category'] as String;
        final currentAmount = category['amount'] as double;
        
        if (currentAmount > monthlyIncome * 0.3) {
          recommendations.add(BudgetRecommendation(
            name: 'Reduce $categoryName',
            amount: currentAmount * 0.8,
            category: categoryName,
            description: 'Consider reducing spending in $categoryName by 20%',
            priority: 'Medium',
          ));
        }
      }
    }

    return recommendations;
  }

  // Predict future spending based on historical data
  Map<String, double> predictFutureSpending(List<Transaction> transactions) {
    if (transactions.isEmpty) return {};

    final predictions = <String, double>{};
    final categoryTransactions = <String, List<Transaction>>{};

    // Group transactions by category
    for (final transaction in transactions) {
      if (!categoryTransactions.containsKey(transaction.category)) {
        categoryTransactions[transaction.category] = [];
      }
      categoryTransactions[transaction.category]!.add(transaction);
    }

    // Calculate average monthly spending for each category
    for (final entry in categoryTransactions.entries) {
      final category = entry.key;
      final categoryTrans = entry.value;
      
      // Calculate average monthly spending
      final totalAmount = categoryTrans.fold(0.0, (sum, t) => sum + t.amount);
      final months = _calculateMonthsSpan(categoryTrans);
      final monthlyAverage = months > 0 ? totalAmount / months : totalAmount;
      
      predictions[category] = monthlyAverage;
    }

    return predictions;
  }

  // Helper method to check if text matches any pattern
  bool _matchesPattern(String text, List<String> patterns) {
    return patterns.any((pattern) => text.contains(pattern));
  }

  // Helper method to calculate months span of transactions
  double _calculateMonthsSpan(List<Transaction> transactions) {
    if (transactions.isEmpty) return 0;
    
    final dates = transactions.map((t) => t.date).toList();
    final earliest = dates.reduce((a, b) => a.isBefore(b) ? a : b);
    final latest = dates.reduce((a, b) => a.isAfter(b) ? a : b);
    
    return latest.difference(earliest).inDays / 30.0;
  }
}

// Budget recommendation model
class BudgetRecommendation {
  final String name;
  final double amount;
  final String category;
  final String description;
  final String priority;

  BudgetRecommendation({
    required this.name,
    required this.amount,
    required this.category,
    required this.description,
    required this.priority,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'category': category,
      'description': description,
      'priority': priority,
    };
  }

  factory BudgetRecommendation.fromJson(Map<String, dynamic> json) {
    return BudgetRecommendation(
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      description: json['description'] as String,
      priority: json['priority'] as String,
    );
  }
}
