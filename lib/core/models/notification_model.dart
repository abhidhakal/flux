import 'package:equatable/equatable.dart';

enum NotificationType {
  budgetAlert,
  spendingReminder,
  financialTip,
  goalMilestone,
  billReminder,
  savingsReminder,
  debtAlert,
  achievement,
}

enum NotificationPriority {
  low,
  medium,
  high,
  urgent,
}

enum NotificationStatus {
  unread,
  read,
  dismissed,
}

class Notification extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationPriority priority;
  final NotificationStatus status;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? dismissedAt;
  final Map<String, dynamic>? metadata;
  final bool isActionable;
  final String? actionTitle;
  final String? actionRoute;

  const Notification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    required this.status,
    required this.createdAt,
    this.readAt,
    this.dismissedAt,
    this.metadata,
    this.isActionable = false,
    this.actionTitle,
    this.actionRoute,
  });

  // Getters
  bool get isUnread => status == NotificationStatus.unread;
  bool get isRead => status == NotificationStatus.read;
  bool get isDismissed => status == NotificationStatus.dismissed;
  Duration get age => DateTime.now().difference(createdAt);

  // Notification type display name
  String get typeDisplayName {
    switch (type) {
      case NotificationType.budgetAlert:
        return 'Budget Alert';
      case NotificationType.spendingReminder:
        return 'Spending Reminder';
      case NotificationType.financialTip:
        return 'Financial Tip';
      case NotificationType.goalMilestone:
        return 'Goal Milestone';
      case NotificationType.billReminder:
        return 'Bill Reminder';
      case NotificationType.savingsReminder:
        return 'Savings Reminder';
      case NotificationType.debtAlert:
        return 'Debt Alert';
      case NotificationType.achievement:
        return 'Achievement';
    }
  }

  // Priority display name
  String get priorityDisplayName {
    switch (priority) {
      case NotificationPriority.low:
        return 'Low';
      case NotificationPriority.medium:
        return 'Medium';
      case NotificationPriority.high:
        return 'High';
      case NotificationPriority.urgent:
        return 'Urgent';
    }
  }

  // Copy with method
  Notification copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    NotificationType? type,
    NotificationPriority? priority,
    NotificationStatus? status,
    DateTime? createdAt,
    DateTime? readAt,
    DateTime? dismissedAt,
    Map<String, dynamic>? metadata,
    bool? isActionable,
    String? actionTitle,
    String? actionRoute,
  }) {
    return Notification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      dismissedAt: dismissedAt ?? this.dismissedAt,
      metadata: metadata ?? this.metadata,
      isActionable: isActionable ?? this.isActionable,
      actionTitle: actionTitle ?? this.actionTitle,
      actionRoute: actionRoute ?? this.actionRoute,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type.name,
      'priority': priority.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'dismissedAt': dismissedAt?.toIso8601String(),
      'metadata': metadata,
      'isActionable': isActionable,
      'actionTitle': actionTitle,
      'actionRoute': actionRoute,
    };
  }

  // From JSON
  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.financialTip,
      ),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => NotificationPriority.medium,
      ),
      status: NotificationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => NotificationStatus.unread,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'] as String)
          : null,
      dismissedAt: json['dismissedAt'] != null
          ? DateTime.parse(json['dismissedAt'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
      isActionable: json['isActionable'] as bool? ?? false,
      actionTitle: json['actionTitle'] as String?,
      actionRoute: json['actionRoute'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        message,
        type,
        priority,
        status,
        createdAt,
        readAt,
        dismissedAt,
        metadata,
        isActionable,
        actionTitle,
        actionRoute,
      ];
}
