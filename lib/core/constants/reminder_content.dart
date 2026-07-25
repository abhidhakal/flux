/// Title/body copy for daily reminder types ('budget_check', 'goal_update',
/// 'expense_log'), shared between the scheduling layer
/// (EnhancedNotificationService) and the trigger layer
/// (NotificationTriggerService) so the two stay in sync.
class ReminderContent {
  final String title;
  final String body;
  final String route;

  const ReminderContent(
      {required this.title, required this.body, required this.route});

  static const _byType = {
    'budget_check': ReminderContent(
      title: 'Budget Check Reminder',
      body: 'Time to check your budget progress and spending habits!',
      route: '/budgets',
    ),
    'goal_update': ReminderContent(
      title: 'Goal Progress Update',
      body: 'Update your goal progress and stay motivated!',
      route: '/goals',
    ),
    'expense_log': ReminderContent(
      title: 'Log Your Expenses',
      body: 'Don\'t forget to log your expenses for today.',
      route: '/transactions',
    ),
  };

  static const _fallback = ReminderContent(
    title: 'Daily Reminder',
    body: 'Your daily financial reminder is here!',
    route: '/',
  );

  static ReminderContent forType(String reminderType) =>
      _byType[reminderType] ?? _fallback;
}
