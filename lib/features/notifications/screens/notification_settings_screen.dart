import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/services/enhanced_notification_service.dart';
import '../../../core/services/subscription_service.dart';
import '../../auth/auth_bloc.dart';
import '../../../shared/widgets/app_snackbar.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final EnhancedNotificationService _notificationService = EnhancedNotificationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = true;
  bool _notificationsEnabled = false;
  bool _isDeveloper = false;
  
  // Notification type preferences
  bool _budgetAlerts = true;
  bool _goalMilestones = true;
  bool _spendingAlerts = true;
  
  // Scheduled notifications
  bool _weeklySummaries = false;
  bool _dailyReminders = false;
  
  int _weeklySummaryDay = 1; // Monday
  int _weeklySummaryHour = 9;
  int _weeklySummaryMinute = 0;
  
  int _dailyReminderHour = 20;
  int _dailyReminderMinute = 0;
  String _dailyReminderType = 'expense_log';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final user = context.read<AuthBloc>().state;
      if (user is AuthAuthenticated) {
        final enabled = await _notificationService.areNotificationsEnabled();
        final isDev = SubscriptionService().isDeveloperUser(); // Sync check since we have user
        
        // Load user preferences from Firestore
        final userDoc = await _firestore.collection('users').doc(user.user.id).get();
        final data = userDoc.data() ?? {};
        final prefs = data['notificationPreferences'] as Map<String, dynamic>? ?? {};
        final schedules = data['notificationSchedules'] as Map<String, dynamic>? ?? {};
        
        setState(() {
          _notificationsEnabled = enabled;
          _isDeveloper = isDev;
          
          // Load notification type preferences
          _budgetAlerts = prefs['budgetAlerts'] ?? true;
          _goalMilestones = prefs['goalMilestones'] ?? true;
          _spendingAlerts = prefs['spendingAlerts'] ?? true;
          
          // Load schedule preferences
          _weeklySummaries = schedules['weekly_summary']?['enabled'] ?? false;
          _dailyReminders = schedules['daily_reminder']?['enabled'] ?? false;
          
          if (schedules['weekly_summary'] != null) {
            _weeklySummaryDay = schedules['weekly_summary']['dayOfWeek'] ?? 1;
            _weeklySummaryHour = schedules['weekly_summary']['hour'] ?? 9;
            _weeklySummaryMinute = schedules['weekly_summary']['minute'] ?? 0;
          }
          
          if (schedules['daily_reminder'] != null) {
            _dailyReminderHour = schedules['daily_reminder']['hour'] ?? 20;
            _dailyReminderMinute = schedules['daily_reminder']['minute'] ?? 0;
            _dailyReminderType = schedules['daily_reminder']['type'] ?? 'expense_log';
          }
        });
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        AppSnackbar.showError(context, message: 'Failed to load settings');
      }
    }
  }

  Future<void> _savePreferences() async {
    try {
      final user = context.read<AuthBloc>().state;
      if (user is AuthAuthenticated) {
        await _firestore.collection('users').doc(user.user.id).set({
          'notificationPreferences': {
            'budgetAlerts': _budgetAlerts,
            'goalMilestones': _goalMilestones,
            'spendingAlerts': _spendingAlerts,
          },
          'updatedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, message: 'Failed to save preferences');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: colorScheme.background,
        foregroundColor: colorScheme.onBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: theme.textTheme.displaySmall?.copyWith(
          fontSize: 24,
          letterSpacing: -1,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPushNotificationCard(colorScheme),
                  const SizedBox(height: 16),
                  _buildAutomaticAlertsCard(colorScheme),
                  const SizedBox(height: 16),
                  _buildScheduledNotificationsCard(colorScheme),
                  if (_isDeveloper) ...[
                    const SizedBox(height: 16),
                    _buildTestNotificationsCard(colorScheme),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildPushNotificationCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (_notificationsEnabled ? AppColors.success : AppColors.error).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _notificationsEnabled ? Icons.notifications_active : Icons.notifications_off,
                  color: _notificationsEnabled ? AppColors.success : AppColors.error,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Push Notifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _notificationsEnabled 
                          ? 'Notifications are enabled'
                          : 'Enable to receive alerts',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _notificationsEnabled,
                onChanged: (value) => _toggleNotifications(),
                activeColor: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAutomaticAlertsCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Automatic Alerts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'These alerts are triggered automatically based on your activity',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 20),
          _buildAlertToggle(
            'Budget Alerts',
            'When you reach 80%, 90%, or exceed your budget',
            Icons.account_balance_wallet_outlined,
            _budgetAlerts,
            (value) {
              setState(() => _budgetAlerts = value);
              _savePreferences();
            },
            colorScheme,
          ),
          const Divider(height: 24),
          _buildAlertToggle(
            'Goal Milestones',
            'When you reach 25%, 50%, 90%, or complete a goal',
            Icons.flag_outlined,
            _goalMilestones,
            (value) {
              setState(() => _goalMilestones = value);
              _savePreferences();
            },
            colorScheme,
          ),
          const Divider(height: 24),
          _buildAlertToggle(
            'Spending Alerts',
            'When unusual spending patterns are detected',
            Icons.trending_up_outlined,
            _spendingAlerts,
            (value) {
              setState(() => _spendingAlerts = value);
              _savePreferences();
            },
            colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertToggle(
    String title,
    String description,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: _notificationsEnabled ? onChanged : null,
          activeColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildScheduledNotificationsCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scheduled Reminders',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Set up recurring reminders to stay on track',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 20),
          
          // Weekly Summary
          _buildScheduleItem(
            'Weekly Summary',
            'Get a summary of your week every ${_getDayName(_weeklySummaryDay)}',
            Icons.calendar_today_outlined,
            _weeklySummaries,
            (value) async {
              setState(() => _weeklySummaries = value);
              if (value) {
                await _scheduleWeeklySummary();
              } else {
                await _cancelWeeklySummary();
              }
            },
            colorScheme,
            onConfigure: _weeklySummaries ? () => _showWeeklySummaryConfig(colorScheme) : null,
          ),
          const Divider(height: 24),
          
          // Daily Reminder
          _buildScheduleItem(
            'Daily Reminder',
            'Reminder at ${_formatTime(_dailyReminderHour, _dailyReminderMinute)}',
            Icons.alarm_outlined,
            _dailyReminders,
            (value) async {
              setState(() => _dailyReminders = value);
              if (value) {
                await _scheduleDailyReminder();
              } else {
                await _cancelDailyReminder();
              }
            },
            colorScheme,
            onConfigure: _dailyReminders ? () => _showDailyReminderConfig(colorScheme) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(
    String title,
    String description,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
    ColorScheme colorScheme, {
    VoidCallback? onConfigure,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (onConfigure != null) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onConfigure,
                      child: Icon(
                        Icons.settings_outlined,
                        size: 18,
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: _notificationsEnabled ? onChanged : null,
          activeColor: AppColors.primary,
        ),
      ],
    );
  }

  String _getDayName(int day) {
    const days = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[day];
  }

  String _formatTime(int hour, int minute) {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _showWeeklySummaryConfig(ColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Weekly Summary Schedule',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              Text('Day', style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _weeklySummaryDay,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: List.generate(7, (i) => DropdownMenuItem(
                  value: i + 1,
                  child: Text(_getDayName(i + 1)),
                )),
                onChanged: (value) {
                  if (value != null) {
                    setModalState(() => _weeklySummaryDay = value);
                    setState(() => _weeklySummaryDay = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              Text('Time', style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _weeklySummaryHour,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: List.generate(24, (i) => DropdownMenuItem(
                        value: i,
                        child: Text(i.toString().padLeft(2, '0')),
                      )),
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() => _weeklySummaryHour = value);
                          setState(() => _weeklySummaryHour = value);
                        }
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(':', style: TextStyle(fontSize: 20, color: colorScheme.onSurface)),
                  ),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _weeklySummaryMinute,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: List.generate(12, (i) => DropdownMenuItem(
                        value: i * 5,
                        child: Text((i * 5).toString().padLeft(2, '0')),
                      )),
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() => _weeklySummaryMinute = value);
                          setState(() => _weeklySummaryMinute = value);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _scheduleWeeklySummary();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDailyReminderConfig(ColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Daily Reminder Schedule',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              Text('Reminder Type', style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _dailyReminderType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: const [
                  DropdownMenuItem(value: 'expense_log', child: Text('Log your expenses')),
                  DropdownMenuItem(value: 'budget_check', child: Text('Check your budget')),
                  DropdownMenuItem(value: 'goal_update', child: Text('Update goal progress')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setModalState(() => _dailyReminderType = value);
                    setState(() => _dailyReminderType = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              Text('Time', style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _dailyReminderHour,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: List.generate(24, (i) => DropdownMenuItem(
                        value: i,
                        child: Text(i.toString().padLeft(2, '0')),
                      )),
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() => _dailyReminderHour = value);
                          setState(() => _dailyReminderHour = value);
                        }
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(':', style: TextStyle(fontSize: 20, color: colorScheme.onSurface)),
                  ),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _dailyReminderMinute,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: List.generate(12, (i) => DropdownMenuItem(
                        value: i * 5,
                        child: Text((i * 5).toString().padLeft(2, '0')),
                      )),
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() => _dailyReminderMinute = value);
                          setState(() => _dailyReminderMinute = value);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _scheduleDailyReminder();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleNotifications() async {
    try {
      if (_notificationsEnabled) {
        await _notificationService.cancelAllScheduledNotifications();
        setState(() => _notificationsEnabled = false);
        if (mounted) AppSnackbar.showInfo(context, message: 'Notifications disabled');
      } else {
        final enabled = await _notificationService.requestPermissions();
        if (enabled) {
          setState(() => _notificationsEnabled = true);
          if (mounted) AppSnackbar.showSuccess(context, message: 'Notifications enabled');
        } else {
          if (mounted) AppSnackbar.showError(context, message: 'Please enable notifications in settings');
        }
      }
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, message: 'Failed to toggle notifications');
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
        if (mounted) AppSnackbar.showSuccess(context, message: 'Weekly summary scheduled');
      }
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, message: 'Failed to schedule: $e');
    }
  }

  Future<void> _cancelWeeklySummary() async {
    try {
      final user = context.read<AuthBloc>().state;
      if (user is AuthAuthenticated) {
        await _firestore.collection('users').doc(user.user.id).set({
          'notificationSchedules': {
            'weekly_summary': {'enabled': false},
          },
        }, SetOptions(merge: true));
      }
    } catch (e) {
      // Silently fail
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
        if (mounted) AppSnackbar.showSuccess(context, message: 'Daily reminder scheduled');
      }
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, message: 'Failed to schedule: $e');
    }
  }

  Future<void> _cancelDailyReminder() async {
    try {
      final user = context.read<AuthBloc>().state;
      if (user is AuthAuthenticated) {
        await _firestore.collection('users').doc(user.user.id).set({
          'notificationSchedules': {
            'daily_reminder': {'enabled': false},
          },
        }, SetOptions(merge: true));
      }
    } catch (e) {
      // Silently fail
    }
  }

  Widget _buildTestNotificationsCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Developer Tools',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Test notification triggers (Developer Only)',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildTestButton('Budget Alert', _testBudgetAlert),
              _buildTestButton('Goal Milestone', _testGoalMilestone),
              _buildTestButton('Spending Alert', _testSpendingAlert),
              _buildTestButton('Financial Tip', _testFinancialTip),
              _buildTestButton('Morning Greeting', _testMorningGreeting),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTestButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: _notificationsEnabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label),
    );
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

  Future<void> _testMorningGreeting() async {
    // Shows immediate notification for testing
    await _notificationService.showFinancialTip(
      title: 'Good Morning ☀️',
      message: 'Rise and shine! Take a moment to track your finances today.',
    );
  }
}
