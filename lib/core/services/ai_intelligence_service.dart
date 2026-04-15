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
      return 'Bills & Utilities';
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
        'healthScore': 0,
        'totalSpent': 0.0,
        'totalIncome': 0.0,
        'averageSpent': 0.0,
        'savingsRate': 0.0,
        'topCategories': [],
        'spendingTrend': 'stable',
        'insights': ['No data to analyze yet.'],
        'recommendations': ['Start tracking your income and expenses to get AI insights'],
        'subscriptions': [],
        'projectedSavings': 0.0,
        'efficiency': {'needs': 0.0, 'wants': 0.0, 'savings': 0.0},
      };
    }

    final expenses = transactions.where((t) => t.isExpense).toList();
    final incomes = transactions.where((t) => t.isIncome).toList();
    final totalSpent = expenses.fold(0.0, (sum, t) => sum + t.amount);
    final totalIncome = incomes.fold<double>(0.0, (sum, t) => sum + t.amount);
    final averageSpent = expenses.isNotEmpty ? totalSpent / expenses.length : 0.0;
    
    final savingsRate = totalIncome > 0 ? ((totalIncome - totalSpent) / totalIncome * 100) : 0.0;

    // 1. Category analysis
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
      'percentage': totalSpent > 0 ? (e.value / totalSpent * 100).toStringAsFixed(1) : '0.0',
    }).toList();

    // 2. Subscription Detection (Crude detection based on recurring titles/amounts)
    final Map<String, List<Transaction>> merchantHistory = {};
    for (final t in expenses) {
      final key = t.title.toLowerCase().trim();
      merchantHistory.putIfAbsent(key, () => []).add(t);
    }

    final subscriptions = <Map<String, dynamic>>[];
    merchantHistory.forEach((title, txs) {
      if (txs.length >= 2) {
        // Simple logic: if same amount or same merchant appears frequently
        final amounts = txs.map((e) => e.amount).toSet();
        if (amounts.length == 1 || txs.length >= 3) {
          subscriptions.add({
            'title': txs.first.title,
            'amount': txs.first.amount,
            'frequency': 'Monthly', // Assume monthly for simplicity
            'category': txs.first.category,
          });
        }
      }
    });

    // 3. Efficiency Calculation (50/30/20 rule)
    double needs = 0, wants = 0;
    for (final t in expenses) {
      // Prioritize user-defined essential status, fallback to category mapping
      if (t.isEssential) {
        needs += t.amount;
      } else if (['Housing', 'Bills & Utilities', 'Healthcare', 'Transportation', 'Education'].contains(t.category)) {
        // Fallback for transactions where user hasn't toggled it yet
        needs += t.amount;
      } else {
        wants += t.amount;
      }
    }
    final efficiency = {
      'needs': totalIncome > 0 ? (needs / totalIncome * 100) : 0.0,
      'wants': totalIncome > 0 ? (wants / totalIncome * 100) : 0.0,
      'savings': savingsRate > 0 ? savingsRate : 0.0,
    };

    // 4. Financial Health Score (0-100)
    int healthScore = 50; // Base score
    healthScore += (savingsRate / 2).clamp(-20, 25).toInt(); // up to +25 for 50% savings
    if (efficiency['needs']! < 50) healthScore += 10;
    if (efficiency['wants']! < 30) healthScore += 10;
    if (totalIncome > totalSpent) healthScore += 5;
    
    // Recent trend impact
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final sixtyDaysAgo = now.subtract(const Duration(days: 60));

    final recentExpenses = expenses.where((t) => t.date.isAfter(thirtyDaysAgo)).toList();
    final previousExpenses = expenses.where((t) => t.date.isAfter(sixtyDaysAgo) && t.date.isBefore(thirtyDaysAgo)).toList();

    final recentTotal = recentExpenses.fold(0.0, (sum, t) => sum + t.amount);
    final previousTotal = previousExpenses.fold(0.0, (sum, t) => sum + t.amount);

    String spendingTrend = 'stable';
    if (previousTotal > 0) {
      final change = (recentTotal - previousTotal) / previousTotal;
      if (change > 0.1) {
        spendingTrend = 'increasing';
        healthScore -= 10;
      }
      else if (change < -0.1) {
        spendingTrend = 'decreasing';
        healthScore += 10;
      }
    }
    healthScore = healthScore.clamp(0, 100);

    // 5. Projected Savings (6 months)
    final monthlySavings = totalIncome - totalSpent;
    final projectedSavings = monthlySavings * 6;

    // Generate insights
    final insights = <String>[];
    
    // Financial Health Insight
    if (healthScore > 80) {
      insights.add('Excellent financial health! You are in the top 5% of savers.');
    } else if (healthScore > 60) {
      insights.add('Good financial health. Your habits are sustainable.');
    } else {
      insights.add('Your financial health needs attention. Consider reviewing your "wants" spending.');
    }

    if (subscriptions.isNotEmpty) {
      final subTotal = subscriptions.fold(0.0, (sum, s) => sum + (s['amount'] as double));
      insights.add('Detected ${subscriptions.length} recurring subscriptions costing you ${CurrencyService().formatAmount(subTotal)} monthly.');
    }

    if (projectedSavings > 0) {
      insights.add('At your current rate, you will save ${CurrencyService().formatAmount(projectedSavings)} in the next 6 months.');
    }

    if (topCategories.isNotEmpty) {
      final topCategory = topCategories.first;
      insights.add('Spending focus: ${topCategory['category']} (${topCategory['percentage']}% of total).');
    }
    
    // Efficiency insight
    if (efficiency['wants']! > 35) {
      insights.add('Your non-essential spending (Wants) is high at ${efficiency['wants']!.toStringAsFixed(1)}%.');
    }

    // Generate recommendations
    final recommendations = <String>[];
    
    if (savingsRate < 20) {
      recommendations.add('Optimize your 50/30/20 balance. Your current savings rate is ${savingsRate.toStringAsFixed(1)}%.');
    }

    if (subscriptions.length > 3) {
      recommendations.add('Review your ${subscriptions.length} subscriptions. Are you using all of them regularly?');
    }

    if (efficiency['needs']! > 60) {
      recommendations.add('Your fixed costs (Needs) are high. Consider downsizing or negotiating bills.');
    }

    recommendations.add('Set up an automated transfer of ${CurrencyService().formatAmount(totalIncome * 0.2)} to savings.');
    
    return {
      'healthScore': healthScore,
      'totalSpent': totalSpent,
      'totalIncome': totalIncome,
      'averageSpent': averageSpent,
      'savingsRate': savingsRate,
      'topCategories': topCategories,
      'spendingTrend': spendingTrend,
      'insights': insights,
      'recommendations': recommendations,
      'recentTotal': recentTotal,
      'previousTotal': previousTotal,
      'subscriptions': subscriptions,
      'projectedSavings': projectedSavings,
      'efficiency': efficiency,
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
