import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/enhanced_notification_service.dart';
import '../../auth/auth_bloc.dart';
import '../../../shared/widgets/app_snackbar.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen>
    with TickerProviderStateMixin {
  final EnhancedNotificationService _notificationService = EnhancedNotificationService();
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isLoading = true;
  bool _notificationsEnabled = false;
  bool _budgetAlerts = true;
  bool _goalMilestones = true;
  bool _spendingAlerts = true;
  bool _weeklySummaries = true;
  bool _dailyReminders = false;
  bool _financialTips = true;
  
  int _weeklySummaryDay = 1; // Monday
  int _weeklySummaryHour = 9;
  int _weeklySummaryMinute = 0;
  
  int _dailyReminderHour = 20;
  int _dailyReminderMinute = 0;
  String _dailyReminderType = 'budget_check';

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    // Initialize animations
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _loadSettings();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final user = context.read<AuthBloc>().state;
      if (user is AuthAuthenticated) {
        final schedules = await _notificationService.getUserNotificationSchedules(user.user.id);
        final enabled = await _notificationService.areNotificationsEnabled();
        
        setState(() {
          _notificationsEnabled = enabled;
          _weeklySummaries = schedules['weekly_summary']?['enabled'] ?? true;
          _dailyReminders = schedules['daily_reminder_budget_check']?['enabled'] ?? false;
          
          if (schedules['weekly_summary'] != null) {
            _weeklySummaryDay = schedules['weekly_summary']['dayOfWeek'] ?? 1;
            _weeklySummaryHour = schedules['weekly_summary']['hour'] ?? 9;
            _weeklySummaryMinute = schedules['weekly_summary']['minute'] ?? 0;
          }
          
          if (schedules['daily_reminder_budget_check'] != null) {
            _dailyReminderHour = schedules['daily_reminder_budget_check']['hour'] ?? 20;
            _dailyReminderMinute = schedules['daily_reminder_budget_check']['minute'] ?? 0;
          }
        });
      }
      
      setState(() => _isLoading = false);
      
      // Start animations after data is loaded
      _fadeController.forward();
      _slideController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      AppSnackbar.showError(context, message: 'Failed to load notification settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.lightTextInverse,
        elevation: 0,
      ),
      body: _isLoading
          ? _buildLoadingState()
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNotificationStatusCard(),
                      const SizedBox(height: 20),
                      _buildNotificationTypesCard(),
                      const SizedBox(height: 20),
                      _buildWeeklySummaryCard(),
                      const SizedBox(height: 20),
                      _buildDailyRemindersCard(),
                      const SizedBox(height: 20),
                      _buildTestNotificationsCard(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading Settings...',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fetching your notification preferences',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationStatusCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _notificationsEnabled ? Icons.notifications_active : Icons.notifications_off,
                  color: _notificationsEnabled ? AppColors.success : AppColors.error,
                ),
                const SizedBox(width: 12),
                Text(
                  'Push Notifications',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _notificationsEnabled 
                  ? 'Notifications are enabled. You\'ll receive alerts for important financial events.'
                  : 'Notifications are disabled. Enable them to stay updated on your financial progress.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _toggleNotifications,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _notificationsEnabled ? AppColors.error : AppColors.success,
                ),
                child: Text(
                  _notificationsEnabled ? 'Disable Notifications' : 'Enable Notifications',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTypesCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Types',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildNotificationSwitch(
              'Budget Alerts',
              'Get notified when you\'re approaching or exceeding budget limits',
              _budgetAlerts,
              (value) => setState(() => _budgetAlerts = value),
              Icons.account_balance_wallet,
            ),
            _buildNotificationSwitch(
              'Goal Milestones',
              'Celebrate when you reach 25%, 50%, 90% of your goals',
              _goalMilestones,
              (value) => setState(() => _goalMilestones = value),
              Icons.flag,
            ),
            _buildNotificationSwitch(
              'Spending Alerts',
              'Get alerts for unusual spending patterns',
              _spendingAlerts,
              (value) => setState(() => _spendingAlerts = value),
              Icons.trending_up,
            ),
            _buildNotificationSwitch(
              'Financial Tips',
              'Receive helpful financial advice and tips',
              _financialTips,
              (value) => setState(() => _financialTips = value),
              Icons.lightbulb,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklySummaryCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(
                  'Weekly Summary',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Get a weekly summary of your financial progress every week',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Weekly Summary'),
              subtitle: const Text('Receive weekly financial summaries'),
              value: _weeklySummaries,
              onChanged: _notificationsEnabled ? (value) {
                setState(() => _weeklySummaries = value);
                if (value) _scheduleWeeklySummary();
              } : null,
              activeColor: AppColors.primary,
            ),
            if (_weeklySummaries) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Day of Week'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          value: _weeklySummaryDay,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('Monday')),
                            DropdownMenuItem(value: 2, child: Text('Tuesday')),
                            DropdownMenuItem(value: 3, child: Text('Wednesday')),
                            DropdownMenuItem(value: 4, child: Text('Thursday')),
                            DropdownMenuItem(value: 5, child: Text('Friday')),
                            DropdownMenuItem(value: 6, child: Text('Saturday')),
                            DropdownMenuItem(value: 7, child: Text('Sunday')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _weeklySummaryDay = value);
                              _scheduleWeeklySummary();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Time'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: _weeklySummaryHour,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                ),
                                items: List.generate(24, (index) => 
                                  DropdownMenuItem(value: index, child: Text('${index.toString().padLeft(2, '0')}'))
                                ),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _weeklySummaryHour = value);
                                    _scheduleWeeklySummary();
                                  }
                                },
                              ),
                            ),
                            const Text(':', style: TextStyle(fontSize: 18)),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: _weeklySummaryMinute,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                ),
                                items: List.generate(60, (index) => 
                                  DropdownMenuItem(value: index, child: Text('${index.toString().padLeft(2, '0')}'))
                                ),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _weeklySummaryMinute = value);
                                    _scheduleWeeklySummary();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDailyRemindersCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(
                  'Daily Reminders',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Get daily reminders to check your budget and log expenses',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Daily Reminders'),
              subtitle: const Text('Receive daily financial reminders'),
              value: _dailyReminders,
              onChanged: _notificationsEnabled ? (value) {
                setState(() => _dailyReminders = value);
                if (value) _scheduleDailyReminder();
              } : null,
              activeColor: AppColors.primary,
            ),
            if (_dailyReminders) ...[
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Reminder Type'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _dailyReminderType,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'budget_check', child: Text('Budget Check')),
                      DropdownMenuItem(value: 'goal_update', child: Text('Goal Progress Update')),
                      DropdownMenuItem(value: 'expense_log', child: Text('Log Expenses')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _dailyReminderType = value);
                        _scheduleDailyReminder();
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _dailyReminderHour,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            labelText: 'Hour',
                          ),
                          items: List.generate(24, (index) => 
                            DropdownMenuItem(value: index, child: Text('${index.toString().padLeft(2, '0')}'))
                          ),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _dailyReminderHour = value);
                              _scheduleDailyReminder();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _dailyReminderMinute,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            labelText: 'Minute',
                          ),
                          items: List.generate(60, (index) => 
                            DropdownMenuItem(value: index, child: Text('${index.toString().padLeft(2, '0')}'))
                          ),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _dailyReminderMinute = value);
                              _scheduleDailyReminder();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTestNotificationsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test Notifications',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Test different types of notifications to see how they look',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _notificationsEnabled ? _testBudgetAlert : null,
                  child: const Text('Budget Alert'),
                ),
                ElevatedButton(
                  onPressed: _notificationsEnabled ? _testGoalMilestone : null,
                  child: const Text('Goal Milestone'),
                ),
                ElevatedButton(
                  onPressed: _notificationsEnabled ? _testSpendingAlert : null,
                  child: const Text('Spending Alert'),
                ),
                ElevatedButton(
                  onPressed: _notificationsEnabled ? _testFinancialTip : null,
                  child: const Text('Financial Tip'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSwitch(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon,
  ) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: _notificationsEnabled ? onChanged : null,
      activeColor: AppColors.primary,
      secondary: Icon(icon, color: AppColors.primary),
    );
  }

  Future<void> _toggleNotifications() async {
    try {
      if (_notificationsEnabled) {
        await _notificationService.cancelAllScheduledNotifications();
        setState(() => _notificationsEnabled = false);
        AppSnackbar.showInfo(context, message: 'Notifications disabled');
      } else {
        final enabled = await _notificationService.requestPermissions();
        if (enabled) {
          setState(() => _notificationsEnabled = true);
          AppSnackbar.showSuccess(context, message: 'Notifications enabled');
        } else {
          AppSnackbar.showError(context, message: 'Failed to enable notifications. Please check app permissions.');
        }
      }
    } catch (e) {
      AppSnackbar.showError(context, message: 'Failed to toggle notifications');
    }
  }

  Future<void> _scheduleWeeklySummary() async {
    try {
      final user = context.read<AuthBloc>().state;
      if (user is AuthAuthenticated) {
        await _notificationService.scheduleWeeklySummary(
          userId: user.user.id,
          dayOfWeek: _weeklySummaryDay,
          hour: _weeklySummaryHour,
          minute: _weeklySummaryMinute,
        );
        AppSnackbar.showSuccess(context, message: 'Weekly summary scheduled');
      }
    } catch (e) {
      AppSnackbar.showError(context, message: 'Failed to schedule weekly summary');
    }
  }

  Future<void> _scheduleDailyReminder() async {
    try {
      final user = context.read<AuthBloc>().state;
      if (user is AuthAuthenticated) {
        await _notificationService.scheduleDailyReminder(
          userId: user.user.id,
          hour: _dailyReminderHour,
          minute: _dailyReminderMinute,
          reminderType: _dailyReminderType,
        );
        AppSnackbar.showSuccess(context, message: 'Daily reminder scheduled');
      }
    } catch (e) {
      AppSnackbar.showError(context, message: 'Failed to schedule daily reminder');
    }
  }

  Future<void> _testBudgetAlert() async {
    await _notificationService.showBudgetAlert(
      budgetName: 'Test Budget',
      percentageUsed: 95.0,
      remaining: 50.0,
    );
  }

  Future<void> _testGoalMilestone() async {
    await _notificationService.showGoalMilestone(
      goalName: 'Test Goal',
      progress: 50.0,
      milestone: '50%',
    );
  }

  Future<void> _testSpendingAlert() async {
    await _notificationService.showSpendingAlert(
      message: 'You\'ve made 3 high-value transactions this week. Review your spending.',
      transactionCount: 3,
    );
  }

  Future<void> _testFinancialTip() async {
    await _notificationService.showFinancialTip(
      title: 'Financial Tip',
      message: 'Consider the 50/30/20 rule: 50% needs, 30% wants, 20% savings.',
    );
  }
}
