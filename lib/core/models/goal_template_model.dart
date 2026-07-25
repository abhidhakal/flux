enum GoalTemplateCategory {
  house,
  car,
  vacation,
  education,
  emergency,
  retirement,
  wedding,
  business,
  health,
  other,
}

enum GoalTemplateDifficulty {
  easy,
  medium,
  hard,
  expert,
}

class GoalTemplate {
  final String id;
  final String name;
  final String description;
  final GoalTemplateCategory category;
  final GoalTemplateDifficulty difficulty;
  final double suggestedAmount;
  final int suggestedDurationMonths;
  final List<String> tags;
  final String icon;
  final Map<String, dynamic> metadata;
  final bool isPopular;
  final double completionRate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GoalTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.suggestedAmount,
    required this.suggestedDurationMonths,
    required this.tags,
    required this.icon,
    required this.metadata,
    this.isPopular = false,
    this.completionRate = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GoalTemplate.fromJson(Map<String, dynamic> json) {
    return GoalTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: GoalTemplateCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => GoalTemplateCategory.other,
      ),
      difficulty: GoalTemplateDifficulty.values.firstWhere(
        (e) => e.name == json['difficulty'],
        orElse: () => GoalTemplateDifficulty.medium,
      ),
      suggestedAmount: (json['suggestedAmount'] as num).toDouble(),
      suggestedDurationMonths: json['suggestedDurationMonths'] as int,
      tags: List<String>.from(json['tags'] ?? []),
      icon: json['icon'] as String,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      isPopular: json['isPopular'] as bool? ?? false,
      completionRate: (json['completionRate'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category.name,
      'difficulty': difficulty.name,
      'suggestedAmount': suggestedAmount,
      'suggestedDurationMonths': suggestedDurationMonths,
      'tags': tags,
      'icon': icon,
      'metadata': metadata,
      'isPopular': isPopular,
      'completionRate': completionRate,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  GoalTemplate copyWith({
    String? id,
    String? name,
    String? description,
    GoalTemplateCategory? category,
    GoalTemplateDifficulty? difficulty,
    double? suggestedAmount,
    int? suggestedDurationMonths,
    List<String>? tags,
    String? icon,
    Map<String, dynamic>? metadata,
    bool? isPopular,
    double? completionRate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GoalTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      suggestedAmount: suggestedAmount ?? this.suggestedAmount,
      suggestedDurationMonths:
          suggestedDurationMonths ?? this.suggestedDurationMonths,
      tags: tags ?? this.tags,
      icon: icon ?? this.icon,
      metadata: metadata ?? this.metadata,
      isPopular: isPopular ?? this.isPopular,
      completionRate: completionRate ?? this.completionRate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'GoalTemplate(id: $id, name: $name, category: $category, difficulty: $difficulty)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GoalTemplate && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
