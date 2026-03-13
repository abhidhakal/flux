import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:uuid/uuid.dart';
import '../models/goal_model.dart';
import '../models/goal_template_model.dart';

class GoalTemplateService {
  final firestore.FirebaseFirestore _firestore = firestore.FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  Future<List<GoalTemplate>> getGoalTemplates() async {
    return getAllTemplates();
  }

  // Get all goal templates
  Future<List<GoalTemplate>> getAllTemplates() async {
    try {
      final querySnapshot = await _firestore
          .collection('goal_templates')
          .orderBy('isPopular', descending: true)
          .orderBy('completionRate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => GoalTemplate.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('GOAL TEMPLATE SERVICE: Error getting templates: $e');
      return _getDefaultTemplates();
    }
  }

  // Get templates by category
  Future<List<GoalTemplate>> getTemplatesByCategory(GoalTemplateCategory category) async {
    try {
      final querySnapshot = await _firestore
          .collection('goal_templates')
          .where('category', isEqualTo: category.name)
          .orderBy('completionRate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => GoalTemplate.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('GOAL TEMPLATE SERVICE: Error getting templates by category: $e');
      return _getDefaultTemplates().where((t) => t.category == category).toList();
    }
  }

  // Get popular templates
  Future<List<GoalTemplate>> getPopularTemplates() async {
    try {
      // First try to get popular templates from Firestore
      final querySnapshot = await _firestore
          .collection('goal_templates')
          .where('isPopular', isEqualTo: true)
          .limit(10)
          .get();

      final templates = querySnapshot.docs
          .map((doc) => GoalTemplate.fromJson(doc.data()))
          .toList();

      // Sort by completion rate locally to avoid index requirement
      templates.sort((a, b) => b.completionRate.compareTo(a.completionRate));
      
      return templates;
    } catch (e) {
      debugPrint('GOAL TEMPLATE SERVICE: Error getting popular templates: $e');
      // Fallback to default templates
      final defaultTemplates = _getDefaultTemplates().where((t) => t.isPopular).toList();
      defaultTemplates.sort((a, b) => b.completionRate.compareTo(a.completionRate));
      return defaultTemplates;
    }
  }

  // Search templates
  Future<List<GoalTemplate>> searchTemplates(String query) async {
    try {
      final allTemplates = await getAllTemplates();
      return allTemplates.where((template) {
        return template.name.toLowerCase().contains(query.toLowerCase()) ||
               template.description.toLowerCase().contains(query.toLowerCase()) ||
               template.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()));
      }).toList();
    } catch (e) {
      debugPrint('GOAL TEMPLATE SERVICE: Error searching templates: $e');
      return [];
    }
  }

  // Create goal from template
  Future<Map<String, dynamic>> createGoalFromTemplate(
    GoalTemplate template,
    String userId, {
    double? customAmount,
    int? customDurationMonths,
    String? customName,
  }) async {
    return {
      'name': customName ?? template.name,
      'description': template.description,
      'targetAmount': customAmount ?? template.suggestedAmount,
      'targetDate': DateTime.now().add(Duration(days: (customDurationMonths ?? template.suggestedDurationMonths) * 30)),
      'category': template.category.name,
      'icon': template.icon,
      'tags': template.tags,
      'metadata': {
        ...template.metadata,
        'createdFromTemplate': true,
        'templateId': template.id,
        'templateDifficulty': template.difficulty.name,
      },
    };
  }

  Future<void> createAndSaveGoalFromTemplate(
    GoalTemplate template,
    String userId, {
    double? customAmount,
    int? customDurationMonths,
    String? customName,
  }) async {
    try {
      final goalData = await createGoalFromTemplate(
        template,
        userId,
        customAmount: customAmount,
        customDurationMonths: customDurationMonths,
        customName: customName,
      );

      final goal = Goal(
        id: _uuid.v4(),
        userId: userId,
        name: goalData['name'] as String,
        description: goalData['description'] as String,
        type: _mapCategoryToGoalType(goalData['category'] as String),
        targetAmount: goalData['targetAmount'] as double,
        currentAmount: 0.0,
        targetDate: goalData['targetDate'] as DateTime,
        status: GoalStatus.active,
        createdAt: DateTime.now(),
        icon: goalData['icon'] as String,
        color: 0xFF0079DC,
        isRecurring: false,
      );

      await _firestore.collection('goals').doc(goal.id).set(goal.toJson());
      await trackTemplateUsage(template.id, userId);
    } catch (e) {
      throw Exception('Failed to create goal from template: $e');
    }
  }

  // Initialize default templates
  Future<void> initializeDefaultTemplates() async {
    try {
      final templates = _getDefaultTemplates();
      
      for (final template in templates) {
        await _firestore
            .collection('goal_templates')
            .doc(template.id)
            .set(template.toJson());
      }
      
      debugPrint('GOAL TEMPLATE SERVICE: Default templates initialized');
    } catch (e) {
      debugPrint('GOAL TEMPLATE SERVICE: Error initializing templates: $e');
    }
  }

  // Get default templates
  List<GoalTemplate> _getDefaultTemplates() {
    final now = DateTime.now();
    
    return [
      // House Templates
      GoalTemplate(
        id: 'house_down_payment',
        name: 'House Down Payment',
        description: 'Save for a 20% down payment on your dream home. This template helps you plan for one of life\'s biggest investments.',
        category: GoalTemplateCategory.house,
        difficulty: GoalTemplateDifficulty.hard,
        suggestedAmount: 50000.0,
        suggestedDurationMonths: 36,
        tags: ['house', 'real estate', 'investment', 'home ownership'],
        icon: '🏠',
        metadata: {
          'downPaymentPercentage': 20,
          'averageHomePrice': 250000,
          'tips': [
            'Consider first-time homebuyer programs',
            'Factor in closing costs (2-5% of home price)',
            'Build emergency fund for home maintenance',
          ],
        },
        isPopular: true,
        completionRate: 0.65,
        createdAt: now,
        updatedAt: now,
      ),
      
      GoalTemplate(
        id: 'home_renovation',
        name: 'Home Renovation',
        description: 'Transform your space with a kitchen remodel, bathroom upgrade, or whole-home renovation.',
        category: GoalTemplateCategory.house,
        difficulty: GoalTemplateDifficulty.medium,
        suggestedAmount: 25000.0,
        suggestedDurationMonths: 18,
        tags: ['renovation', 'home improvement', 'kitchen', 'bathroom'],
        icon: '🔨',
        metadata: {
          'renovationTypes': ['kitchen', 'bathroom', 'basement', 'exterior'],
          'tips': [
            'Get multiple quotes from contractors',
            'Set aside 10-20% extra for unexpected costs',
            'Consider DIY options for simple projects',
          ],
        },
        isPopular: true,
        completionRate: 0.72,
        createdAt: now,
        updatedAt: now,
      ),

      // Car Templates
      GoalTemplate(
        id: 'new_car',
        name: 'New Car Purchase',
        description: 'Buy your dream car with cash or a substantial down payment to reduce financing costs.',
        category: GoalTemplateCategory.car,
        difficulty: GoalTemplateDifficulty.medium,
        suggestedAmount: 35000.0,
        suggestedDurationMonths: 24,
        tags: ['car', 'vehicle', 'transportation', 'automobile'],
        icon: '🚗',
        metadata: {
          'carTypes': ['sedan', 'suv', 'truck', 'luxury', 'electric'],
          'tips': [
            'Consider total cost of ownership (insurance, maintenance)',
            'Research resale value before buying',
            'Factor in registration and taxes',
          ],
        },
        isPopular: true,
        completionRate: 0.68,
        createdAt: now,
        updatedAt: now,
      ),

      GoalTemplate(
        id: 'car_maintenance_fund',
        name: 'Car Maintenance Fund',
        description: 'Build a fund for regular maintenance, repairs, and unexpected car expenses.',
        category: GoalTemplateCategory.car,
        difficulty: GoalTemplateDifficulty.easy,
        suggestedAmount: 5000.0,
        suggestedDurationMonths: 12,
        tags: ['maintenance', 'repairs', 'emergency', 'vehicle care'],
        icon: '🔧',
        metadata: {
          'maintenanceTypes': ['oil changes', 'tires', 'brakes', 'battery', 'emergency repairs'],
          'tips': [
            'Follow manufacturer\'s maintenance schedule',
            'Keep receipts for warranty claims',
            'Consider extended warranty options',
          ],
        },
        isPopular: false,
        completionRate: 0.85,
        createdAt: now,
        updatedAt: now,
      ),

      // Vacation Templates
      GoalTemplate(
        id: 'dream_vacation',
        name: 'Dream Vacation',
        description: 'Plan and save for that once-in-a-lifetime trip you\'ve always wanted to take.',
        category: GoalTemplateCategory.vacation,
        difficulty: GoalTemplateDifficulty.medium,
        suggestedAmount: 8000.0,
        suggestedDurationMonths: 18,
        tags: ['travel', 'vacation', 'trip', 'adventure', 'relaxation'],
        icon: '✈️',
        metadata: {
          'destinationTypes': ['international', 'domestic', 'cruise', 'adventure', 'luxury'],
          'tips': [
            'Book flights 2-3 months in advance for best prices',
            'Consider travel insurance for expensive trips',
            'Research visa requirements and travel documents',
          ],
        },
        isPopular: true,
        completionRate: 0.78,
        createdAt: now,
        updatedAt: now,
      ),

      GoalTemplate(
        id: 'annual_vacation',
        name: 'Annual Vacation Fund',
        description: 'Set aside money each year for regular vacations and getaways.',
        category: GoalTemplateCategory.vacation,
        difficulty: GoalTemplateDifficulty.easy,
        suggestedAmount: 3000.0,
        suggestedDurationMonths: 12,
        tags: ['annual', 'regular', 'getaway', 'family trip'],
        icon: '🏖️',
        metadata: {
          'vacationTypes': ['weekend getaways', 'family trips', 'romantic getaways', 'solo travel'],
          'tips': [
            'Plan ahead to take advantage of early booking discounts',
            'Consider off-season travel for better deals',
            'Set up automatic transfers to make saving effortless',
          ],
        },
        isPopular: true,
        completionRate: 0.82,
        createdAt: now,
        updatedAt: now,
      ),

      // Education Templates
      GoalTemplate(
        id: 'college_fund',
        name: 'College Education Fund',
        description: 'Save for higher education expenses including tuition, books, and living costs.',
        category: GoalTemplateCategory.education,
        difficulty: GoalTemplateDifficulty.hard,
        suggestedAmount: 100000.0,
        suggestedDurationMonths: 60,
        tags: ['education', 'college', 'tuition', 'student loans', 'future'],
        icon: '🎓',
        metadata: {
          'educationTypes': ['undergraduate', 'graduate', 'professional', 'trade school'],
          'tips': [
            'Research 529 plans and education savings accounts',
            'Consider community college for first two years',
            'Look into scholarships and grants',
          ],
        },
        isPopular: true,
        completionRate: 0.58,
        createdAt: now,
        updatedAt: now,
      ),

      GoalTemplate(
        id: 'professional_development',
        name: 'Professional Development',
        description: 'Invest in your career with courses, certifications, conferences, and skill development.',
        category: GoalTemplateCategory.education,
        difficulty: GoalTemplateDifficulty.easy,
        suggestedAmount: 2000.0,
        suggestedDurationMonths: 6,
        tags: ['career', 'skills', 'certification', 'training', 'growth'],
        icon: '📚',
        metadata: {
          'developmentTypes': ['online courses', 'certifications', 'conferences', 'workshops', 'books'],
          'tips': [
            'Check if your employer offers tuition reimbursement',
            'Look for free online courses and resources',
            'Network at professional events',
          ],
        },
        isPopular: false,
        completionRate: 0.75,
        createdAt: now,
        updatedAt: now,
      ),

      // Emergency Templates
      GoalTemplate(
        id: 'emergency_fund',
        name: 'Emergency Fund',
        description: 'Build a safety net to cover 3-6 months of expenses in case of job loss or unexpected expenses.',
        category: GoalTemplateCategory.emergency,
        difficulty: GoalTemplateDifficulty.medium,
        suggestedAmount: 15000.0,
        suggestedDurationMonths: 18,
        tags: ['emergency', 'safety net', 'financial security', 'unexpected'],
        icon: '🛡️',
        metadata: {
          'emergencyTypes': ['job loss', 'medical emergency', 'car repair', 'home repair', 'family emergency'],
          'tips': [
            'Keep emergency fund in high-yield savings account',
            'Don\'t invest emergency fund in volatile assets',
            'Review and adjust amount based on life changes',
          ],
        },
        isPopular: true,
        completionRate: 0.45,
        createdAt: now,
        updatedAt: now,
      ),

      // Retirement Templates
      GoalTemplate(
        id: 'retirement_catch_up',
        name: 'Retirement Catch-Up',
        description: 'Accelerate your retirement savings if you\'re behind on your retirement goals.',
        category: GoalTemplateCategory.retirement,
        difficulty: GoalTemplateDifficulty.hard,
        suggestedAmount: 50000.0,
        suggestedDurationMonths: 48,
        tags: ['retirement', '401k', 'ira', 'future', 'financial independence'],
        icon: '🏝️',
        metadata: {
          'retirementTypes': ['401k', 'IRA', 'roth ira', 'pension', 'social security'],
          'tips': [
            'Maximize employer 401k matching',
            'Consider catch-up contributions if over 50',
            'Diversify retirement accounts',
          ],
        },
        isPopular: false,
        completionRate: 0.38,
        createdAt: now,
        updatedAt: now,
      ),

      // Wedding Templates
      GoalTemplate(
        id: 'wedding_fund',
        name: 'Wedding Fund',
        description: 'Save for your dream wedding, including venue, catering, photography, and all the special details.',
        category: GoalTemplateCategory.wedding,
        difficulty: GoalTemplateDifficulty.medium,
        suggestedAmount: 25000.0,
        suggestedDurationMonths: 24,
        tags: ['wedding', 'marriage', 'celebration', 'special day'],
        icon: '💍',
        metadata: {
          'weddingTypes': ['traditional', 'destination', 'intimate', 'luxury', 'budget-friendly'],
          'tips': [
            'Create a detailed wedding budget spreadsheet',
            'Consider weekday or off-season weddings for savings',
            'Prioritize what matters most to you',
          ],
        },
        isPopular: true,
        completionRate: 0.71,
        createdAt: now,
        updatedAt: now,
      ),

      // Business Templates
      GoalTemplate(
        id: 'startup_fund',
        name: 'Business Startup Fund',
        description: 'Launch your own business with sufficient capital for initial expenses and operating costs.',
        category: GoalTemplateCategory.business,
        difficulty: GoalTemplateDifficulty.expert,
        suggestedAmount: 50000.0,
        suggestedDurationMonths: 36,
        tags: ['business', 'startup', 'entrepreneur', 'investment', 'independence'],
        icon: '🚀',
        metadata: {
          'businessTypes': ['online', 'retail', 'service', 'manufacturing', 'consulting'],
          'tips': [
            'Create a detailed business plan',
            'Research market and competition',
            'Consider small business loans and grants',
          ],
        },
        isPopular: false,
        completionRate: 0.42,
        createdAt: now,
        updatedAt: now,
      ),

      // Health Templates
      GoalTemplate(
        id: 'health_emergency_fund',
        name: 'Health Emergency Fund',
        description: 'Prepare for unexpected medical expenses, procedures, or health-related emergencies.',
        category: GoalTemplateCategory.health,
        difficulty: GoalTemplateDifficulty.medium,
        suggestedAmount: 10000.0,
        suggestedDurationMonths: 24,
        tags: ['health', 'medical', 'emergency', 'wellness', 'insurance'],
        icon: '🏥',
        metadata: {
          'healthTypes': ['medical emergency', 'dental work', 'surgery', 'therapy', 'medications'],
          'tips': [
            'Review your health insurance coverage',
            'Consider health savings accounts (HSA)',
            'Keep medical receipts for tax deductions',
          ],
        },
        isPopular: false,
        completionRate: 0.67,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  // Track template usage
  Future<void> trackTemplateUsage(String templateId, String userId) async {
    try {
      await _firestore
          .collection('goal_templates')
          .doc(templateId)
          .collection('usage')
          .doc(userId)
          .set({
        'userId': userId,
        'usedAt': DateTime.now().toIso8601String(),
        'templateId': templateId,
      });
    } catch (e) {
      debugPrint('GOAL TEMPLATE SERVICE: Error tracking usage: $e');
    }
  }

  // Get template usage statistics
  Future<Map<String, dynamic>> getTemplateStats(String templateId) async {
    try {
      final usageSnapshot = await _firestore
          .collection('goal_templates')
          .doc(templateId)
          .collection('usage')
          .get();

      return {
        'totalUsage': usageSnapshot.docs.length,
        'recentUsage': usageSnapshot.docs
            .where((doc) {
              final usedAt = DateTime.parse(doc.data()['usedAt']);
              return DateTime.now().difference(usedAt).inDays <= 30;
            })
            .length,
      };
    } catch (e) {
      debugPrint('GOAL TEMPLATE SERVICE: Error getting stats: $e');
      return {'totalUsage': 0, 'recentUsage': 0};
    }
  }

  GoalType _mapCategoryToGoalType(String category) {
    switch (category.toLowerCase()) {
      case 'house':
      case 'home':
        return GoalType.home;
      case 'vacation':
      case 'travel':
        return GoalType.vacation;
      case 'education':
      case 'school':
        return GoalType.education;
      case 'emergency':
        return GoalType.emergency;
      case 'retirement':
        return GoalType.investment;
      default:
        return GoalType.other;
    }
  }
}
